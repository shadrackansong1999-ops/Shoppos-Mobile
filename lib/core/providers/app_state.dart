import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/license_service.dart';
import '../services/sync_engine.dart';

enum AppStage { loading, needsLicenseSetup, locked, needsLogin, ready }

/// Root app state. Decides which screen the app boots into (license setup
/// / lock / login / main shell) and holds the logged-in user + last sync
/// result for anything in the tree to read.
class AppState extends ChangeNotifier {
  AppStage stage = AppStage.loading;
  LicenseStatus? licenseStatus;
  AppUser? get currentUser => AuthService.instance.currentUser;

  SyncResult? lastSyncResult;
  bool isSyncing = false;

  Future<void> bootstrap() async {
    await AuthService.instance.ensureDefaultAdmin();
    await _refreshLicense();
    if (stage == AppStage.needsLicenseSetup || stage == AppStage.locked) {
      notifyListeners();
      return;
    }
    final restored = await AuthService.instance.restoreSession();
    stage = restored != null ? AppStage.ready : AppStage.needsLogin;
    notifyListeners();

    if (stage == AppStage.ready) {
      // Fire-and-forget background sync on launch - never blocks the UI.
      syncNow();
    }
  }

  Future<void> _refreshLicense() async {
    final status = await LicenseService.instance.getStatus();
    licenseStatus = status;
    if (!status.configured) {
      stage = AppStage.needsLicenseSetup;
    } else if (status.locked) {
      stage = AppStage.locked;
    }
  }

  Future<void> onLicenseConfigured() async {
    await _refreshLicense();
    final restored = await AuthService.instance.restoreSession();
    stage = restored != null ? AppStage.ready : AppStage.needsLogin;
    notifyListeners();
  }

  Future<void> onUnlocked() async {
    await _refreshLicense();
    if (stage != AppStage.locked) {
      final restored = await AuthService.instance.restoreSession();
      stage = restored != null ? AppStage.ready : AppStage.needsLogin;
    }
    notifyListeners();
  }

  Future<String?> login(String username, String password) async {
    final error = await AuthService.instance.login(username, password);
    if (error == null) {
      stage = AppStage.ready;
      notifyListeners();
      syncNow();
    }
    return error;
  }

  Future<void> logout() async {
    await AuthService.instance.logout();
    stage = AppStage.needsLogin;
    notifyListeners();
  }

  Future<void> syncNow() async {
    if (isSyncing) return;
    isSyncing = true;
    notifyListeners();
    lastSyncResult = await SyncEngine.instance.runFullSync();
    isSyncing = false;
    // A trial could have just expired while the app was open - re-check.
    await _refreshLicense();
    if (stage == AppStage.locked) {
      // handled by the widget tree watching `stage`
    }
    notifyListeners();
  }
}
