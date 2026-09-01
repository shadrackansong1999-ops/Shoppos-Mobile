import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/app_state.dart';
import '../../../core/repositories/sales_repository.dart';
import '../../../core/theme.dart';
import '../../../core/utils/formatters.dart';

/// mineOnly=true -> "My Sales" (cashier sees only their own transactions).
/// mineOnly=false -> "Sales History" (admin/manager, sees everyone's).
class SalesHistoryScreen extends StatefulWidget {
  final bool mineOnly;
  const SalesHistoryScreen({super.key, this.mineOnly = false});
  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final _repo = SalesRepository();
  List<Map<String, dynamic>> _sales = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final username = context.read<AppState>().currentUser?.username;
    final sales = await _repo.history(cashier: widget.mineOnly ? username : null);
    setState(() {
      _sales = sales;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canVoid = context.read<AppState>().currentUser?.can('void_sale') ?? false;
    final canDelete = context.read<AppState>().currentUser?.can('delete_sale') ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(widget.mineOnly ? 'My Sales' : 'Sales History')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _sales.isEmpty
                ? const Center(child: Text('No sales recorded'))
                : ListView.builder(
                    itemCount: _sales.length,
                    itemBuilder: (ctx, i) {
                      final s = _sales[i];
                      final voided = s['status'] == 'voided';
                      return ListTile(
                        title: Text(s['invoice_number'] as String, style: TextStyle(decoration: voided ? TextDecoration.lineThrough : null)),
                        subtitle: Text('${s['cashier'] ?? ''} - ${formatDate(DateTime.parse(s['created_at'] as String))}'),
                        trailing: Text(Money.format(s['total'] as num),
                            style: TextStyle(fontWeight: FontWeight.bold, color: voided ? Colors.grey : null)),
                        onTap: () => _openDetail(s, canVoid, canDelete),
                      );
                    },
                  ),
      ),
    );
  }

  Future<void> _openDetail(Map<String, dynamic> sale, bool canVoid, bool canDelete) async {
    final items = await _repo.itemsForSale(sale['id'] as String);
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(sale['invoice_number'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('${sale['cashier']} - ${sale['payment_method']} - ${sale['status']}'),
            const Divider(),
            ...items.map((it) => ListTile(
                  dense: true,
                  title: Text(it['product_name'] as String),
                  subtitle: Text('${it['quantity']} x ${Money.format(it['unit_price'] as num)}'),
                  trailing: Text(Money.format(it['total'] as num)),
                )),
            const Divider(),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(Money.format(sale['total'] as num), style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
            if (sale['status'] == 'completed' && (canVoid || canDelete)) ...[
              const SizedBox(height: 12),
              Row(children: [
                if (canVoid)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await _repo.voidSale(sale['id'] as String);
                        if (ctx.mounted) Navigator.pop(ctx);
                        _load();
                      },
                      child: const Text('Void Sale'),
                    ),
                  ),
                if (canVoid && canDelete) const SizedBox(width: 10),
                if (canDelete)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: AppTheme.red),
                      onPressed: () async {
                        await _repo.deleteSale(sale['id'] as String);
                        if (ctx.mounted) Navigator.pop(ctx);
                        _load();
                      },
                      child: const Text('Delete'),
                    ),
                  ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}
