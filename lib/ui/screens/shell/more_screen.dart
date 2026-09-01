import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../core/providers/app_state.dart';
import '../modules/simple_crud_screens.dart';
import '../modules/orders_screen.dart';
import '../modules/product_logs_screen.dart';
import '../modules/reports_screen.dart';
import '../modules/sales_history_screen.dart';
import '../modules/settings_screen.dart';
import '../modules/users_screen.dart';
import '../modules/remote_screen.dart';
import '../modules/monitor_screen.dart';

class _MoreItem {
  final String perm;
  final String label;
  final IconData icon;
  final Widget Function() build;
  const _MoreItem(this.perm, this.label, this.icon, this.build);
}

final List<_MoreItem> _items = [
  _MoreItem(Perm.categories, 'Categories', Icons.category, () => CategoriesScreen()),
  _MoreItem(Perm.suppliers, 'Suppliers', Icons.factory, () => SuppliersScreen()),
  _MoreItem(Perm.customers, 'Customers', Icons.people, () => CustomersScreen()),
  _MoreItem(Perm.orders, 'Purchase Orders', Icons.local_shipping, () => const OrdersScreen()),
  _MoreItem(Perm.productLogs, 'Product Logs', Icons.history, () => const ProductLogsScreen()),
  _MoreItem(Perm.mySales, 'My Sales', Icons.receipt, () => const SalesHistoryScreen(mineOnly: true)),
  _MoreItem(Perm.reports, 'Reports', Icons.bar_chart, () => const ReportsScreen()),
  _MoreItem(Perm.expenses, 'Expenses', Icons.money_off, () => ExpensesScreen()),
  _MoreItem(Perm.monitor, 'Live Monitor', Icons.monitor_heart, () => const MonitorScreen()),
  _MoreItem(Perm.users, 'Users', Icons.admin_panel_settings, () => const UsersScreen()),
  _MoreItem(Perm.settings, 'Settings', Icons.settings, () => const SettingsScreen()),
  _MoreItem(Perm.remote, 'Remote / Sync', Icons.cloud_sync, () => const RemoteScreen()),
];

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().currentUser;
    final visible = _items.where((i) => user?.can(i.perm) ?? false).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: visible.isEmpty
          ? const Center(child: Text('Nothing else available for your account'))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.95,
              ),
              itemCount: visible.length,
              itemBuilder: (ctx, i) {
                final item = visible[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => item.build())),
                  child: Card(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item.icon, size: 28),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(item.label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
