import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/app_state.dart';
import '../../../core/services/license_service.dart';
import '../../../core/theme.dart';

class LicenseSetupScreen extends StatefulWidget {
  const LicenseSetupScreen({super.key});
  @override
  State<LicenseSetupScreen> createState() => _LicenseSetupScreenState();
}

class _LicenseSetupScreenState extends State<LicenseSetupScreen> {
  String _mode = 'trial';
  final _daysCtrl = TextEditingController(text: '14');
  final _pwCtrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _daysCtrl.dispose();
    _pwCtrl.dispose();
    _pw2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _busy = true;
    });
    String? error;
    if (_mode == 'trial') {
      final days = int.tryParse(_daysCtrl.text.trim());
      if (days == null || days < 1) {
        error = 'Enter a valid trial duration.';
      } else if (_pwCtrl.text.length < 4) {
        error = 'Unlock password must be at least 4 characters.';
      } else if (_pwCtrl.text != _pw2Ctrl.text) {
        error = 'Unlock passwords do not match.';
      } else {
        error = await LicenseService.instance.setupTrial(trialDays: days, unlockPassword: _pwCtrl.text);
      }
    } else {
      error = await LicenseService.instance.setupUnrestricted();
    }
    setState(() {
      _busy = false;
      _error = error;
    });
    if (error == null && mounted) {
      await context.read<AppState>().onLicenseConfigured();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.storefront, size: 40, color: AppTheme.blue),
                      const SizedBox(height: 12),
                      const Text('Set Up ShopPOS', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      const Text('Choose how this device should run', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 20),
                      if (_error != null)
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(color: const Color(0xFFFED7D7), borderRadius: BorderRadius.circular(8)),
                          child: Text(_error!, style: const TextStyle(color: AppTheme.red)),
                        ),
                      RadioListTile<String>(
                        value: 'trial',
                        groupValue: _mode,
                        onChanged: (v) => setState(() => _mode = v!),
                        title: const Text('Free Trial'),
                        subtitle: const Text('Runs for a set number of days, then locks'),
                      ),
                      RadioListTile<String>(
                        value: 'unrestricted',
                        groupValue: _mode,
                        onChanged: (v) => setState(() => _mode = v!),
                        title: const Text('Unrestricted'),
                        subtitle: const Text('No trial limit - license already purchased'),
                      ),
                      if (_mode == 'trial') ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: _daysCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Trial duration (days)'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _pwCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Unlock password'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _pw2Ctrl,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Confirm unlock password'),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Keep this safe - entering it after the trial ends removes the time limit permanently on this device.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _busy ? null : _submit,
                        child: _busy ? const CircularProgressIndicator(color: Colors.white) : const Text('Start ShopPOS'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
