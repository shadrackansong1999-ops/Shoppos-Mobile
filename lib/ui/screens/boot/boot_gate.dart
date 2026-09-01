import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/app_state.dart';
import '../auth/license_setup_screen.dart';
import '../auth/license_lock_screen.dart';
import '../auth/login_screen.dart';
import '../shell/app_shell.dart';

class BootGate extends StatelessWidget {
  const BootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    switch (app.stage) {
      case AppStage.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AppStage.needsLicenseSetup:
        return const LicenseSetupScreen();
      case AppStage.locked:
        return const LicenseLockScreen();
      case AppStage.needsLogin:
        return const LoginScreen();
      case AppStage.ready:
        return const AppShell();
    }
  }
}
