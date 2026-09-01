import 'dart:convert';
import 'package:uuid/uuid.dart';

import '../db/base_repository.dart';
import '../db/database_helper.dart';
import '../utils/password_hash.dart';

const _uuid = Uuid();

class PurchaseOrdersRepository {
  final _orders = BaseRepository('purchase_orders');

  Future<List<Map<String, dynamic>>> getAll() => _orders.getAll(orderBy: 'created_at DESC');

  Future<List<Map<String, dynamic>>> itemsForOrder(String orderId) async {
    final db = await DatabaseHelper.instance.database;
    return db.query('purchase_order_items', where: 'order_id = ? AND is_deleted = 0', whereArgs: [orderId]);
  }

  Future<String> create({
    required String supplierId,
    required List<Map<String, dynamic>> items, // {product_id, product_name, quantity_ordered, unit_cost}
    String? notes,
    DateTime? expectedDate,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final orderId = _uuid.v4();
    final now = DateTime.now().toUtc().toIso8601String();
    final orderNumber = 'PO-M-${DateTime.now().millisecondsSinceEpoch}';
    final total = items.fold<num>(
      0, (sum, i) => sum + (i['unit_cost'] as num) * (i['quantity_ordered'] as num));

    await db.transaction((txn) async {
      await txn.insert('purchase_orders', {
        'id': orderId,
        'order_number': orderNumber,
        'supplier_id': supplierId,
        'status': 'pending',
        'total': total,
        'notes': notes,
        'expected_date': expectedDate?.toIso8601String(),
        'received_date': null,
        'created_at': now,
        'updated_at': now,
        'is_dirty': 1,
        'is_deleted': 0,
      });
      for (final item in items) {
        await txn.insert('purchase_order_items', {
          'id': _uuid.v4(),
          'order_id': orderId,
          'product_id': item['product_id'],
          'product_name': item['product_name'],
          'quantity_ordered': item['quantity_ordered'],
          'quantity_received': 0,
          'unit_cost': item['unit_cost'],
          'total': (item['unit_cost'] as num) * (item['quantity_ordered'] as num),
          'updated_at': now,
          'is_dirty': 1,
          'is_deleted': 0,
        });
      }
    });
    return orderNumber;
  }

  /// Marks a PO received and adds the received quantities back into stock.
  Future<void> receive(String orderId) async {
    final db = await DatabaseHelper.instance.database;
    final items = await itemsForOrder(orderId);
    final now = DateTime.now().toUtc().toIso8601String();

    await db.transaction((txn) async {
      for (final item in items) {
        final qty = item['quantity_ordered'] as num;
        final productId = item['product_id'] as String;
        final productRows = await txn.query('products', where: 'id = ?', whereArgs: [productId]);
        if (productRows.isNotEmpty) {
          final currentQty = productRows.first['quantity'] as num;
          await txn.update('products', {'quantity': currentQty + qty, 'updated_at': now, 'is_dirty': 1},
              where: 'id = ?', whereArgs: [productId]);
          await txn.insert('stock_movements', {
            'id': _uuid.v4(),
            'product_id': productId,
            'movement_type': 'purchase_receive',
            'quantity': qty,
            'reference': item['order_id'],
            'notes': null,
            'created_at': now,
            'updated_at': now,
            'is_dirty': 1,
            'is_deleted': 0,
          });
        }
        await txn.update('purchase_order_items', {'quantity_received': qty, 'updated_at': now, 'is_dirty': 1},
            where: 'id = ?', whereArgs: [item['id']]);
      }
      await txn.update(
        'purchase_orders',
        {'status': 'received', 'received_date': now, 'updated_at': now, 'is_dirty': 1},
        where: 'id = ?',
        whereArgs: [orderId],
      );
    });
  }
}

class UsersRepository {
  final _repo = BaseRepository('users');

  Future<List<Map<String, dynamic>>> getAll() => _repo.getAll(orderBy: 'username COLLATE NOCASE ASC');

  Future<String> create({
    required String username,
    required String fullName,
    required String password,
    required String role,
    List<String>? permissions,
  }) {
    return _repo.insert({
      'username': username.trim(),
      'full_name': fullName.trim(),
      'password_hash': hashPassword(password),
      'role': role,
      'custom_permissions': permissions != null ? jsonEncode(permissions) : null,
      'is_active': 1,
      'last_login': null,
    });
  }

  Future<void> update(
    String id, {
    required String fullName,
    required String role,
    required bool isActive,
    String? newPassword,
    List<String>? permissions,
    bool useRoleDefaults = false,
  }) {
    final data = <String, dynamic>{
      'full_name': fullName.trim(),
      'role': role,
      'is_active': isActive ? 1 : 0,
    };
    if (newPassword != null && newPassword.isNotEmpty) {
      data['password_hash'] = hashPassword(newPassword);
    }
    if (useRoleDefaults) {
      data['custom_permissions'] = null;
    } else if (permissions != null) {
      data['custom_permissions'] = jsonEncode(permissions);
    }
    return _repo.update(id, data);
  }

  Future<void> deactivate(String id) => _repo.update(id, {'is_active': 0});
}

class SettingsRepository {
  final _repo = BaseRepository('settings');

  Future<String?> get(String key) async {
    final rows = await _repo.getAll(where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<Map<String, String>> getAllAsMap() async {
    final rows = await _repo.getAll();
    return {for (final r in rows) r['key'] as String: (r['value'] as String? ?? '')};
  }

  Future<void> set(String key, String value) async {
    final rows = await _repo.getAll(where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) {
      await _repo.insert({'key': key, 'value': value}, hasCreatedAt: false);
    } else {
      await _repo.update(rows.first['id'] as String, {'value': value});
    }
  }
}
