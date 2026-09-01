import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/app_state.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/repositories/products_repository.dart';
import '../../../core/repositories/sales_repository.dart';
import '../../../core/repositories/simple_repositories.dart';
import '../../../core/theme.dart';
import '../../../core/utils/formatters.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});
  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _productsRepo = ProductsRepository();
  final _customersRepo = CustomersRepository();
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _customers = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final products = await _productsRepo.getAll(searchQuery: _query);
    final customers = await _customersRepo.getAll();
    if (!mounted) return;
    setState(() {
      _products = products;
      _customers = customers;
    });
  }

  void _openCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CartSheet(customers: _customers, onCheckedOut: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Point of Sale')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search or scan a product'),
              onChanged: (v) {
                _query = v;
                _load();
              },
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.15,
              ),
              itemCount: _products.length,
              itemBuilder: (ctx, i) {
                final p = _products[i];
                final qty = p['quantity'] as num;
                final outOfStock = qty <= 0;
                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: outOfStock
                        ? null
                        : () => context.read<CartProvider>().addProduct(
                              productId: p['id'] as String,
                              name: p['name'] as String,
                              unitPrice: p['selling_price'] as num,
                              stock: qty,
                            ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(p['name'] as String, maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          Text(Money.format(p['selling_price'] as num), style: const TextStyle(color: AppTheme.blue, fontWeight: FontWeight.bold)),
                          Text(outOfStock ? 'Out of stock' : '$qty ${p['unit']} left',
                              style: TextStyle(fontSize: 11, color: outOfStock ? AppTheme.red : Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: cart.isEmpty ? null : _openCart,
        backgroundColor: cart.isEmpty ? Colors.grey : AppTheme.blue,
        icon: const Icon(Icons.shopping_cart),
        label: Text(cart.isEmpty ? 'Cart empty' : '${cart.items.length} items - ${Money.format(cart.total)}'),
      ),
    );
  }
}

class _CartSheet extends StatefulWidget {
  final List<Map<String, dynamic>> customers;
  final VoidCallback onCheckedOut;
  const _CartSheet({required this.customers, required this.onCheckedOut});
  @override
  State<_CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<_CartSheet> {
  String _paymentMethod = 'Cash';
  final _amountCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text('Cart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: cart.items.length,
                itemBuilder: (ctx, i) {
                  final item = cart.items[i];
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text('${Money.format(item.unitPrice)} x ${item.quantity}'),
                    leading: IconButton(icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => context.read<CartProvider>().setQuantity(item.productId, item.quantity - 1)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => context.read<CartProvider>().setQuantity(item.productId, item.quantity + 1)),
                      Text(Money.format(item.total)),
                    ]),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: cart.customerId,
                    decoration: const InputDecoration(labelText: 'Customer (optional)'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Walk-in customer')),
                      ...widget.customers.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['name'] as String))),
                    ],
                    onChanged: (v) => context.read<CartProvider>().setCustomer(v),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _paymentMethod,
                    decoration: const InputDecoration(labelText: 'Payment Method'),
                    items: const [
                      DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'Mobile Money', child: Text('Mobile Money')),
                      DropdownMenuItem(value: 'Card', child: Text('Card')),
                    ],
                    onChanged: (v) => setState(() => _paymentMethod = v!),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Amount Paid (Total: ${Money.format(cart.total)})'),
                  ),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(Money.format(cart.total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ]),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _busy ? null : () => _checkout(context, cart),
                    child: _busy ? const CircularProgressIndicator(color: Colors.white) : const Text('Complete Sale'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkout(BuildContext context, CartProvider cart) async {
    final paid = num.tryParse(_amountCtrl.text) ?? 0;
    if (paid < cart.total) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Amount paid is less than the total')));
      return;
    }
    setState(() => _busy = true);
    final appState = context.read<AppState>();
    final lines = cart.items
        .map((i) => CartLine(productId: i.productId, productName: i.name, quantity: i.quantity, unitPrice: i.unitPrice, discount: i.discount))
        .toList();
    await SalesRepository().checkout(
      items: lines,
      cashier: appState.currentUser?.username ?? 'unknown',
      customerId: cart.customerId,
      subtotal: cart.subtotal,
      discount: cart.discountTotal,
      tax: cart.tax,
      total: cart.total,
      amountPaid: paid,
      changeGiven: paid - cart.total,
      paymentMethod: _paymentMethod,
    );
    cart.clear();
    setState(() => _busy = false);
    if (context.mounted) {
      Navigator.pop(context);
      widget.onCheckedOut();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sale completed')));
    }
    appState.syncNow();
  }
}
