import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/app_state.dart';
import '../../../core/services/api_client.dart';
import '../../../core/theme.dart';

/// The desktop app's "Remote Access" module lets an admin reach the shop's
/// terminal from elsewhere. On a phone that already IS the remote device,
/// the equivalent control is: which server does this phone sync with, and
/// is that connection actually working.
class RemoteScreen extends StatefulWidget {
  const RemoteScreen({super.key});
  @override
  State<RemoteScreen> createState() => _RemoteScreenState();
}

class _RemoteScreenState extends State<RemoteScreen> {
  final _urlCtrl = TextEditingController();
  String? _testResult;
  bool _testing = false;
  bool _saving = false;

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final url = await ApiClient.instance.getBaseUrl();
    setState(() => _urlCtrl.text = url ?? '');
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ApiClient.instance.setBaseUrl(_urlCtrl.text);
    setState(() => _saving = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Server address saved')));
  }

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    await ApiClient.instance.setBaseUrl(_urlCtrl.text);
    final ok = await ApiClient.instance.ping();
    setState(() {
      _testing = false;
      _testResult = ok ? 'Connected successfully' : 'Could not reach that server';
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Remote / Sync Server')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('This phone syncs its offline data with the server below - '
              'the same cloud backend the desktop app and any other terminals use, '
              'so everyone converges on the same products, sales, and stock.',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          TextField(
            controller: _urlCtrl,
            decoration: const InputDecoration(labelText: 'Server Address', hintText: 'https://shop.example.com'),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OutlinedButton(onPressed: _testing ? null : _test, child: _testing ? const CircularProgressIndicator() : const Text('Test Connection')),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(onPressed: _saving ? null : _save, child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save')),
            ),
          ]),
          if (_testResult != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_testResult!, style: TextStyle(color: _testResult!.startsWith('Connected') ? AppTheme.green : AppTheme.red)),
            ),
          const Divider(height: 40),
          const Text('Sync Status', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (app.lastSyncResult == null)
            const Text('No sync has run yet on this device.')
          else ...[
            Text('Last push: ${app.lastSyncResult!.pushed} record(s)'),
            Text('Last pull: ${app.lastSyncResult!.pulled} record(s)'),
            if (app.lastSyncResult!.hasErrors)
              ...app.lastSyncResult!.errors.map((e) => Text(e, style: const TextStyle(color: AppTheme.red, fontSize: 12))),
          ],
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.sync),
            label: const Text('Sync Now'),
            onPressed: app.isSyncing ? null : () => app.syncNow(),
          ),
        ],
      ),
    );
  }
}
