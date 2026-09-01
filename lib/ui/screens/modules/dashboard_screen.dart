import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/app_state.dart';
import '../../../core/repositories/products_repository.dart';
import '../../../core/repositories/sales_repository.dart';
import '../../../core/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../widgets/kpi_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _salesRepo = SalesRepository();
  final _productsRepo = ProductsRepository();
  num _todayTotal = 0;
  int _todayCount = 0;
  int _lowStockCount = 0;
  List<Map<String, dynamic>> _recent = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final todaySales = await _salesRepo.history(from: startOfDay);
    final completed = todaySales.where((s) => s['status'] == 'completed');
    final lowStock = await _productsRepo.lowStock();
    final recent = await _salesRepo.history();

    if (!mounted) return;
    setState(() {
      _todayTotal = completed.fold<num>(0, (sum, s) => sum + (s['total'] as num));
      _todayCount = completed.length;
      _lowStockCount = lowStock.length;
      _recent = recent.take(8).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: app.isSyncing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Icon(app.lastSyncResult?.hasErrors == true ? Icons.sync_problem : Icons.sync),
            onPressed: app.isSyncing ? null : () => app.syncNow(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _load();
          await app.syncNow();
        },
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Text('Welcome, ${app.currentUser?.fullName ?? ''}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.5,
                    children: [
                      KpiCard(label: "Today's Sales", value: Money.format(_todayTotal), icon: Icons.point_of_sale, accent: Theme.of(context).colorScheme.primary),
                      KpiCard(label: 'Transactions', value: '$_todayCount', icon: Icons.receipt_long, accent: AppTheme.green),
                      KpiCard(label: 'Low Stock', value: '$_lowStockCount', icon: Icons.inventory_2, accent: AppTheme.amber),
                      KpiCard(
                        label: 'Sync Status',
                        value: app.lastSyncResult == null ? 'Not synced' : (app.lastSyncResult!.hasErrors ? 'Issues' : 'Up to date'),
                        icon: Icons.cloud_sync,
                        accent: app.lastSyncResult?.hasErrors == true ? AppTheme.red : AppTheme.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Recent Sales', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  if (_recent.isEmpty)
                    const Padding(padding: EdgeInsets.all(20), child: Text('No sales yet'))
                  else
                    ..._recent.map((s) => Card(
                          child: ListTile(
                            title: Text(s['invoice_number'] as String),
                            subtitle: Text('${s['cashier'] ?? ''} - ${s['payment_method']}'),
                            trailing: Text(Money.format(s['total'] as num), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        )),
                ],
              ),
      ),
    );
  }
}
