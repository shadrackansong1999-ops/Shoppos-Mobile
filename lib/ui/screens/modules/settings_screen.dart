import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/app_state.dart';
import '../../../core/repositories/misc_repositories.dart';
import '../../../core/theme.dart';
import '../../../core/utils/formatters.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _repo = SettingsRepository();
  final _shopNameCtrl = TextEditingController();
  final _shopAddressCtrl = TextEditingController();
  final _shopPhoneCtrl = TextEditingController();
  final _currencyCtrl = TextEditingController();
  final _taxRateCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _shopAddressCtrl.dispose();
    _shopPhoneCtrl.dispose();
    _currencyCtrl.dispose();
    _taxRateCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final m = await _repo.getAllAsMap();
    _shopNameCtrl.text = m['shop_name'] ?? '';
    _shopAddressCtrl.text = m['shop_address'] ?? '';
    _shopPhoneCtrl.text = m['shop_phone'] ?? '';
    _currencyCtrl.text = m['currency'] ?? 'GHS';
    _taxRateCtrl.text = m['tax_rate'] ?? '0';
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await _repo.set('shop_name', _shopNameCtrl.text.trim());
    await _repo.set('shop_address', _shopAddressCtrl.text.trim());
    await _repo.set('shop_phone', _shopPhoneCtrl.text.trim());
    await _repo.set('currency', _currencyCtrl.text.trim());
    await _repo.set('tax_rate', _taxRateCtrl.text.trim());
    Money.currencySymbol = _currencyCtrl.text.trim().isEmpty ? 'GHS' : _currencyCtrl.text.trim();
    setState(() => _saving = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Shop Info', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(controller: _shopNameCtrl, decoration: const InputDecoration(labelText: 'Shop Name')),
                const SizedBox(height: 10),
                TextField(controller: _shopAddressCtrl, decoration: const InputDecoration(labelText: 'Address')),
                const SizedBox(height: 10),
                TextField(controller: _shopPhoneCtrl, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
                const SizedBox(height: 20),
                const Text('Sales', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(controller: _currencyCtrl, decoration: const InputDecoration(labelText: 'Currency Symbol')),
                const SizedBox(height: 10),
                TextField(controller: _taxRateCtrl, decoration: const InputDecoration(labelText: 'Tax Rate %'), keyboardType: TextInputType.number),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: _saving ? null : _save, child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Settings')),
                const Divider(height: 40),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person),
                  title: Text(app.currentUser?.fullName ?? ''),
                  subtitle: Text('${app.currentUser?.username ?? ''} - ${app.currentUser?.role ?? ''}'),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: AppTheme.red),
                  onPressed: () => app.logout(),
                  child: const Text('Sign Out'),
                ),
              ],
            ),
    );
  }
}
