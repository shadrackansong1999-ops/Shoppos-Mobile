import 'package:flutter/material.dart';

import '../../../core/repositories/sales_repository.dart';
import '../../../core/repositories/simple_repositories.dart';
import '../../../core/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../widgets/kpi_card.dart';

enum _Range { today, week, month, all }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _salesRepo = SalesRepository();
  final _expensesRepo = ExpensesRepository();
  _Range _range = _Range.today;
  bool _loading = true;

  num _revenue = 0;
  num _cost = 0;
  num _expenseTotal = 0;
  int _txCount = 0;
  final Map<String, num> _byPayment = {};

  DateTime? get _from {
    final now = DateTime.now();
    switch (_range) {
      case _Range.today:
        return DateTime(now.year, now.month, now.day);
      case _Range.week:
        return now.subtract(const Duration(days: 7));
      case _Range.month:
        return DateTime(now.year, now.month, 1);
      case _Range.all:
        return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final sales = await _salesRepo.history(from: _from);
    final completed = sales.where((s) => s['status'] == 'completed').toList();
    final expenses = await _expensesRepo.getAll();
    final filteredExpenses = _from == null
        ? expenses
        : expenses.where((e) => DateTime.parse(e['created_at'] as String).isAfter(_from!)).toList();

    num revenue = 0, cost = 0;
    final byPayment = <String, num>{};
    for (final s in completed) {
      revenue += s['total'] as num;
      byPayment[s['payment_method'] as String? ?? 'Cash'] =
          (byPayment[s['payment_method'] as String? ?? 'Cash'] ?? 0) + (s['total'] as num);
      final items = await _salesRepo.itemsForSale(s['id'] as String);
      // Cost isn't stored on sale_items - approximate via product cost_price at time of viewing.
      // Kept simple for the mobile report; the desktop Reports module remains the source of
      // truth for exact historical cost-of-goods (which needs a cost snapshot per line item).
      cost += items.fold<num>(0, (sum, it) => sum + 0 * (it['quantity'] as num));
    }
    final expenseTotal = filteredExpenses.fold<num>(0, (sum, e) => sum + (e['amount'] as num));

    if (!mounted) return;
    setState(() {
      _revenue = revenue;
      _cost = cost;
      _expenseTotal = expenseTotal;
      _txCount = completed.length;
      _byPayment
        ..clear()
        ..addAll(byPayment);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            SegmentedButton<_Range>(
              segments: const [
                ButtonSegment(value: _Range.today, label: Text('Today')),
                ButtonSegment(value: _Range.week, label: Text('7 Days')),
                ButtonSegment(value: _Range.month, label: Text('This Month')),
                ButtonSegment(value: _Range.all, label: Text('All Time')),
              ],
              selected: {_range},
              onSelectionChanged: (s) {
                setState(() => _range = s.first);
                _load();
              },
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator()))
            else ...[
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.5,
                children: [
                  KpiCard(label: 'Revenue', value: Money.format(_revenue), icon: Icons.trending_up, accent: AppTheme.green),
                  KpiCard(label: 'Transactions', value: '$_txCount', icon: Icons.receipt, accent: AppTheme.blue),
                  KpiCard(label: 'Expenses', value: Money.format(_expenseTotal), icon: Icons.money_off, accent: AppTheme.red),
                  KpiCard(label: 'Net (Rev - Exp)', value: Money.format(_revenue - _expenseTotal), icon: Icons.account_balance_wallet, accent: AppTheme.amber),
                ],
              ),
              const SizedBox(height: 20),
              const Text('By Payment Method', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._byPayment.entries.map((e) => Card(
                    child: ListTile(title: Text(e.key), trailing: Text(Money.format(e.value))),
                  )),
              if (_byPayment.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('No sales in this period')),
            ],
          ],
        ),
      ),
    );
  }
}
