import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/app_state.dart';
import '../../../core/services/license_service.dart';
import '../../../core/theme.dart';

class LicenseLockScreen extends StatefulWidget {
  const LicenseLockScreen({super.key});
  @override
  State<LicenseLockScreen> createState() => _LicenseLockScreenState();
}

class _LicenseLockScreenState extends State<LicenseLockScreen> {
  final _pwCtrl = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _pwCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_pwCtrl.text.isEmpty) {
      setState(() => _error = 'Enter the unlock password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await LicenseService.instance.unlock(_pwCtrl.text);
    setState(() {
      _busy = false;
      _error = error;
    });
    if (error == null && mounted) {
      await context.read<AppState>().onUnlocked();
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
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.lock_outline, size: 40, color: AppTheme.red),
                      const SizedBox(height: 12),
                      const Text('Trial Ended', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      const Text('Enter the unlock password to continue', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 20),
                      if (_error != null)
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(color: const Color(0xFFFED7D7), borderRadius: BorderRadius.circular(8)),
                          child: Text(_error!, style: const TextStyle(color: AppTheme.red)),
                        ),
                      TextField(
                        controller: _pwCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Unlock password'),
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _busy ? null : _submit,
                        child: _busy ? const CircularProgressIndicator(color: Colors.white) : const Text('Unlock'),
                      ),
                      const SizedBox(height: 10),
                      const Text("Contact your ShopPOS provider if you don't have this password.",
                          textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
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
