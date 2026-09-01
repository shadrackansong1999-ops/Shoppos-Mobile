import 'package:flutter/material.dart';

import '../../../core/repositories/misc_repositories.dart';
import '../../../core/repositories/products_repository.dart';
import '../../../core/repositories/simple_repositories.dart';
import '../../../core/utils/formatters.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _repo = PurchaseOrdersRepository();
  final _suppliersRepo = SuppliersRepository();
  final _productsRepo = ProductsRepository();
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final orders = await _repo.getAll();
    final suppliers = await _suppliersRepo.getAll();
    final products = await _productsRepo.getAll();
    setState(() {
      _orders = orders;
      _suppliers = suppliers;
      _products = products;
      _loading = false;
    });
  }

  String _supplierName(String? id) =>
      _suppliers.where((s) => s['id'] == id).map((s) => s['name'] as String).firstOrNull ?? 'Unknown supplier';

  Future<void> _openNewOrder() async {
    if (_suppliers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a supplier first')));
      return;
    }
    String? supplierId = _suppliers.first['id'] as String;
    final lines = <Map<String, dynamic>>[];
    String? selectedProduct = _products.isNotEmpty ? _products.first['id'] as String : null;
    final qtyCtrl = TextEditingController(text: '1');
    final costCtrl = TextEditingController(text: '0');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('New Purchase Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: supplierId,
                  decoration: const InputDecoration(labelText: 'Supplier'),
                  items: _suppliers.map((s) => DropdownMenuItem(value: s['id'] as String, child: Text(s['name'] as String))).toList(),
                  onChanged: (v) => supplierId = v,
                ),
                const Divider(height: 24),
                const Text('Add items', style: TextStyle(fontWeight: FontWeight.bold)),
                if (_products.isNotEmpty)
                  Row(children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedProduct,
                        decoration: const InputDecoration(labelText: 'Product'),
                        items: _products.map((p) => DropdownMenuItem(value: p['id'] as String, child: Text(p['name'] as String))).toList(),
                        onChanged: (v) => selectedProduct = v,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Qty'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Unit Cost'))),
                  ]),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add line'),
                  onPressed: () {
                    if (selectedProduct == null) return;
                    final product = _products.firstWhere((p) => p['id'] == selectedProduct);
                    setSheetState(() => lines.add({
                          'product_id': selectedProduct,
                          'product_name': product['name'],
                          'quantity_ordered': num.tryParse(qtyCtrl.text) ?? 1,
                          'unit_cost': num.tryParse(costCtrl.text) ?? 0,
                        }));
                  },
                ),
                ...lines.map((l) => ListTile(
                      dense: true,
                      title: Text(l['product_name'] as String),
                      subtitle: Text('${l['quantity_ordered']} x ${Money.format(l['unit_cost'] as num)}'),
                    )),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: lines.isEmpty
                      ? null
                      : () async {
                          await _repo.create(supplierId: supplierId!, items: lines);
                          if (ctx.mounted) Navigator.pop(ctx);
                          _load();
                        },
                  child: const Text('Create Order'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Purchase Orders')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _orders.isEmpty
                ? const Center(child: Text('No purchase orders yet'))
                : ListView.builder(
                    itemCount: _orders.length,
                    itemBuilder: (ctx, i) {
                      final o = _orders[i];
                      final pending = o['status'] == 'pending';
                      return ListTile(
                        title: Text(o['order_number'] as String),
                        subtitle: Text('${_supplierName(o['supplier_id'] as String?)} - ${o['status']}'),
                        trailing: pending
                            ? TextButton(
                                onPressed: () async {
                                  await _repo.receive(o['id'] as String);
                                  _load();
                                },
                                child: const Text('Receive'))
                            : Text(Money.format(o['total'] as num)),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: _openNewOrder, child: const Icon(Icons.add)),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
