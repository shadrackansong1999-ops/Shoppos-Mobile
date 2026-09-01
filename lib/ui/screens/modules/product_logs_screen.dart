import 'package:flutter/material.dart';

import '../../../core/db/database_helper.dart';
import '../../../core/repositories/products_repository.dart';
import '../../../core/theme.dart';
import '../../../core/utils/formatters.dart';

class ProductLogsScreen extends StatefulWidget {
  const ProductLogsScreen({super.key});
  @override
  State<ProductLogsScreen> createState() => _ProductLogsScreenState();
}

class _ProductLogsScreenState extends State<ProductLogsScreen> {
  final _productsRepo = ProductsRepository();
  List<Map<String, dynamic>> _movements = [];
  Map<String, String> _productNames = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = await DatabaseHelper.instance.database;
    final movements = await db.query('stock_movements', where: 'is_deleted = 0', orderBy: 'created_at DESC', limit: 200);
    final products = await _productsRepo.getAll(activeOnly: false);
    setState(() {
      _movements = movements;
      _productNames = {for (final p in products) p['id'] as String: p['name'] as String};
      _loading = false;
    });
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'sale':
        return Icons.point_of_sale;
      case 'purchase_receive':
        return Icons.local_shipping;
      default:
        return Icons.swap_vert;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Logs')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _movements.isEmpty
                ? const Center(child: Text('No stock movements yet'))
                : ListView.builder(
                    itemCount: _movements.length,
                    itemBuilder: (ctx, i) {
                      final m = _movements[i];
                      final qty = m['quantity'] as num;
                      return ListTile(
                        leading: Icon(_iconFor(m['movement_type'] as String), color: qty < 0 ? AppTheme.red : AppTheme.green),
                        title: Text(_productNames[m['product_id']] ?? 'Unknown product'),
                        subtitle: Text('${m['movement_type']} - ${formatDate(DateTime.parse(m['created_at'] as String))}'),
                        trailing: Text('${qty > 0 ? '+' : ''}$qty', style: TextStyle(fontWeight: FontWeight.bold, color: qty < 0 ? AppTheme.red : AppTheme.green)),
                      );
                    },
                  ),
      ),
    );
  }
}
