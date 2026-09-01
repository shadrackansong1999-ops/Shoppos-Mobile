import 'package:flutter/material.dart';

import '../../../core/repositories/products_repository.dart';
import '../../../core/repositories/simple_repositories.dart';
import '../../../core/theme.dart';
import '../../../core/utils/formatters.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _repo = ProductsRepository();
  final _catRepo = CategoriesRepository();
  final _supRepo = SuppliersRepository();
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _suppliers = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final products = await _repo.getAll(searchQuery: _query);
    final cats = await _catRepo.getAll();
    final sups = await _supRepo.getAll();
    setState(() {
      _products = products;
      _categories = cats;
      _suppliers = sups;
      _loading = false;
    });
  }

  String? _categoryName(String? id) => _categories.where((c) => c['id'] == id).map((c) => c['name'] as String).firstOrNull;

  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final skuCtrl = TextEditingController(text: existing?['sku'] ?? '');
    final barcodeCtrl = TextEditingController(text: existing?['barcode'] ?? '');
    final costCtrl = TextEditingController(text: existing?['cost_price']?.toString() ?? '0');
    final priceCtrl = TextEditingController(text: existing?['selling_price']?.toString() ?? '0');
    final qtyCtrl = TextEditingController(text: existing?['quantity']?.toString() ?? '0');
    final reorderCtrl = TextEditingController(text: existing?['reorder_level']?.toString() ?? '10');
    final unitCtrl = TextEditingController(text: existing?['unit'] ?? 'pcs');
    String? categoryId = existing?['category_id'] as String?;
    String? supplierId = existing?['supplier_id'] as String?;
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(existing == null ? 'Add Product' : 'Edit Product', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: TextFormField(controller: skuCtrl, decoration: const InputDecoration(labelText: 'SKU'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextFormField(controller: barcodeCtrl, decoration: const InputDecoration(labelText: 'Barcode'))),
                  ]),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: categoryId,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: _categories.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['name'] as String))).toList(),
                    onChanged: (v) => setSheetState(() => categoryId = v),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: supplierId,
                    decoration: const InputDecoration(labelText: 'Supplier'),
                    items: _suppliers.map((s) => DropdownMenuItem(value: s['id'] as String, child: Text(s['name'] as String))).toList(),
                    onChanged: (v) => setSheetState(() => supplierId = v),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: TextFormField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cost Price'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextFormField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Selling Price'))),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: TextFormField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextFormField(controller: reorderCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Reorder Level'))),
                  ]),
                  const SizedBox(height: 10),
                  TextFormField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Unit (pcs, kg, box...)')),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final data = {
                        'name': nameCtrl.text.trim(),
                        'sku': skuCtrl.text.trim(),
                        'barcode': barcodeCtrl.text.trim(),
                        'category_id': categoryId,
                        'supplier_id': supplierId,
                        'cost_price': num.tryParse(costCtrl.text) ?? 0,
                        'selling_price': num.tryParse(priceCtrl.text) ?? 0,
                        'quantity': num.tryParse(qtyCtrl.text) ?? 0,
                        'reorder_level': num.tryParse(reorderCtrl.text) ?? 10,
                        'unit': unitCtrl.text.trim().isEmpty ? 'pcs' : unitCtrl.text.trim(),
                        'is_active': 1,
                      };
                      if (existing == null) {
                        await _repo.create(data);
                      } else {
                        await _repo.update(existing['id'] as String, data);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                      _load();
                    },
                    child: const Text('Save'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search name, SKU, barcode'),
                onChanged: (v) {
                  _query = v;
                  _load();
                },
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _products.isEmpty
                      ? const Center(child: Text('No products yet'))
                      : ListView.builder(
                          itemCount: _products.length,
                          itemBuilder: (ctx, i) {
                            final p = _products[i];
                            final qty = p['quantity'] as num;
                            final reorder = p['reorder_level'] as num;
                            final low = qty <= reorder;
                            return ListTile(
                              title: Text(p['name'] as String),
                              subtitle: Text('${_categoryName(p['category_id'] as String?) ?? 'Uncategorized'} - ${Money.format(p['selling_price'] as num)}'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('$qty ${p['unit']}', style: TextStyle(fontWeight: FontWeight.bold, color: low ? AppTheme.red : null)),
                                  if (low) const Text('Low stock', style: TextStyle(fontSize: 10, color: AppTheme.red)),
                                ],
                              ),
                              onTap: () => _openForm(existing: p),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add)),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
