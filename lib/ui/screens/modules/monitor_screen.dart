import 'package:flutter/material.dart';

import '../../../core/db/base_repository.dart';
import '../../../core/db/database_helper.dart';
import '../../../core/theme.dart';
import '../../widgets/kpi_card.dart';

/// Desktop "Live Monitor" watches every terminal from one screen. On a
/// single phone, the useful equivalent is this device's own live status:
/// how much unsynced work is sitting locally, and connectivity.
class MonitorScreen extends StatefulWidget {
  const MonitorScreen({super.key});
  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  Map<String, int> _dirtyCounts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final counts = <String, int>{};
    for (final table in DatabaseHelper.syncableTables) {
      final dirty = await BaseRepository(table).dirtyRows();
      if (dirty.isNotEmpty) counts[table] = dirty.length;
    }
    setState(() {
      _dirtyCounts = counts;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalPending = _dirtyCounts.values.fold<int>(0, (a, b) => a + b);
    return Scaffold(
      appBar: AppBar(title: const Text('Live Monitor')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  KpiCard(
                    label: 'Pending Sync',
                    value: '$totalPending record(s)',
                    icon: Icons.cloud_upload,
                    accent: totalPending == 0 ? AppTheme.green : AppTheme.amber,
                  ),
                  const SizedBox(height: 16),
                  if (_dirtyCounts.isEmpty)
                    const Padding(padding: EdgeInsets.all(20), child: Text('Everything on this device is synced.'))
                  else
                    ..._dirtyCounts.entries.map((e) => Card(
                          child: ListTile(
                            title: Text(e.key.replaceAll('_', ' ')),
                            trailing: Text('${e.value} pending'),
                          ),
                        )),
                ],
              ),
      ),
    );
  }
}
