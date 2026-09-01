import 'package:uuid/uuid.dart';

import '../db/database_helper.dart';

const _uuid = Uuid();

/// A single line in the cart / a completed sale.
class CartLine {
  final String productId;
  final String productName;
  final num quantity;
  final num unitPrice;
  final num discount;
  CartLine({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0,
  });
  num get total => (unitPrice * quantity) - discount;
}

class SalesRepository {
  /// Runs the whole checkout - sale header, line items, and per-product
  /// stock decrement - as one SQLite transaction, so a crash mid-checkout
  /// can never leave stock decremented without a matching sale record (or
  /// vice versa).
  Future<String> checkout({
    required List<CartLine> items,
    required String cashier,
    String? customerId,
    required num subtotal,
    required num discount,
    required num tax,
    required num total,
    required num amountPaid,
    required num changeGiven,
    required String paymentMethod,
    String? notes,
    String terminal = 'mobile',
  }) async {
    final db = await DatabaseHelper.instance.database;
    final saleId = _uuid.v4();
    final now = DateTime.now().toUtc().toIso8601String();
    final invoiceNumber = 'INV-M-${DateTime.now().millisecondsSinceEpoch}';

    await db.transaction((txn) async {
      await txn.insert('sales', {
        'id': saleId,
        'invoice_number': invoiceNumber,
        'customer_id': customerId,
        'subtotal': subtotal,
        'discount': discount,
        'tax': tax,
        'total': total,
        'amount_paid': amountPaid,
        'change_given': changeGiven,
        'payment_method': paymentMethod,
        'status': 'completed',
        'notes': notes,
        'cashier': cashier,
        'terminal': terminal,
        'created_at': now,
        'updated_at': now,
        'is_dirty': 1,
        'is_deleted': 0,
      });

      for (final item in items) {
        await txn.insert('sale_items', {
          'id': _uuid.v4(),
          'sale_id': saleId,
          'product_id': item.productId,
          'product_name': item.productName,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'discount': item.discount,
          'total': item.total,
          'updated_at': now,
          'is_dirty': 1,
          'is_deleted': 0,
        });

        final productRows = await txn.query('products', where: 'id = ?', whereArgs: [item.productId]);
        if (productRows.isNotEmpty) {
          final currentQty = productRows.first['quantity'] as num;
          await txn.update(
            'products',
            {'quantity': currentQty - item.quantity, 'updated_at': now, 'is_dirty': 1},
            where: 'id = ?',
            whereArgs: [item.productId],
          );
          await txn.insert('stock_movements', {
            'id': _uuid.v4(),
            'product_id': item.productId,
            'movement_type': 'sale',
            'quantity': -item.quantity,
            'reference': invoiceNumber,
            'notes': null,
            'created_at': now,
            'updated_at': now,
            'is_dirty': 1,
            'is_deleted': 0,
          });
        }
      }
    });

    return invoiceNumber;
  }

  Future<List<Map<String, dynamic>>> history({String? cashier, DateTime? from, DateTime? to}) async {
    final db = await DatabaseHelper.instance.database;
    final clauses = <String>['is_deleted = 0'];
    final args = <Object?>[];
    if (cashier != null) {
      clauses.add('cashier = ?');
      args.add(cashier);
    }
    if (from != null) {
      clauses.add('created_at >= ?');
      args.add(from.toUtc().toIso8601String());
    }
    if (to != null) {
      clauses.add('created_at <= ?');
      args.add(to.toUtc().toIso8601String());
    }
    return db.query('sales', where: clauses.join(' AND '), whereArgs: args, orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> itemsForSale(String saleId) async {
    final db = await DatabaseHelper.instance.database;
    return db.query('sale_items', where: 'sale_id = ? AND is_deleted = 0', whereArgs: [saleId]);
  }

  Future<void> voidSale(String saleId) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'sales',
      {'status': 'voided', 'updated_at': DateTime.now().toUtc().toIso8601String(), 'is_dirty': 1},
      where: 'id = ?',
      whereArgs: [saleId],
    );
  }

  Future<void> deleteSale(String saleId) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'sales',
      {'is_deleted': 1, 'updated_at': DateTime.now().toUtc().toIso8601String(), 'is_dirty': 1},
      where: 'id = ?',
      whereArgs: [saleId],
    );
  }
}
