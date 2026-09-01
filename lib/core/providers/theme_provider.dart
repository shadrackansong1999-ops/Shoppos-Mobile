import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme.dart';

/// Which color theme is active. Persisted locally per device (a shop
/// might run different terminals in different themes, same as the
/// desktop app treats it as a per-installation choice, not a synced
/// business setting).
class ThemeProvider extends ChangeNotifier {
  static const _prefKey = 'app_theme_key';

  String _key = '';
  String get key => _key;
  ThemeSpec get spec => AppThemes.byKey(_key);
  ThemeData get themeData => AppThemes.build(spec);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _key = prefs.getString(_prefKey) ?? '';
    notifyListeners();
  }

  Future<void> setTheme(String key) async {
    _key = key;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, key);
  }
}
