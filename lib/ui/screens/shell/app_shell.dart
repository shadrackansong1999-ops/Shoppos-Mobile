import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../core/providers/app_state.dart';
import '../modules/dashboard_screen.dart';
import '../modules/pos_screen.dart';
import '../modules/products_screen.dart';
import '../modules/sales_history_screen.dart';
import 'more_screen.dart';

class _Tab {
  final String perm;
  final String label;
  final IconData icon;
  final Widget Function() build;
  const _Tab(this.perm, this.label, this.icon, this.build);
}

/// The five bottom-nav slots are the modules used every shift. Everything
/// else (Categories, Suppliers, Customers, Orders, Product Logs, Reports,
/// Expenses, Users, Settings, Remote, Monitor) lives one tap away behind
/// "More", filtered by the signed-in user's permissions same as these.
final List<_Tab> _primaryTabs = [
  _Tab(Perm.dashboard, 'Home', Icons.dashboard, () => const DashboardScreen()),
  _Tab(Perm.pos, 'POS', Icons.point_of_sale, () => const PosScreen()),
  _Tab(Perm.products, 'Products', Icons.inventory_2, () => const ProductsScreen()),
  _Tab(Perm.sales, 'Sales', Icons.receipt_long, () => const SalesHistoryScreen()),
];

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().currentUser;
    final tabs = _primaryTabs.where((t) => user?.can(t.perm) ?? false).toList();
    // Cashiers (no 'sales' perm) still need somewhere useful - fall back to
    // My Sales in that slot instead of hiding it entirely.
    final effectiveTabs = tabs.isNotEmpty
        ? tabs
        : [_Tab(Perm.pos, 'POS', Icons.point_of_sale, () => const PosScreen())];
    final safeIndex = _index.clamp(0, effectiveTabs.length); // + 1 slot for "More"

    return Scaffold(
      body: safeIndex < effectiveTabs.length ? effectiveTabs[safeIndex].build() : const MoreScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        onTap: (i) => setState(() => _index = i),
        items: [
          ...effectiveTabs.map((t) => BottomNavigationBarItem(icon: Icon(t.icon), label: t.label)),
          const BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'More'),
        ],
      ),
    );
  }
}
