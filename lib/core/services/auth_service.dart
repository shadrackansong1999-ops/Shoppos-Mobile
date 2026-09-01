import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../db/base_repository.dart';
import '../utils/password_hash.dart';

class AppUser {
  final String id;
  final String username;
  final String fullName;
  final String role;
  final bool isActive;
  final List<String> permissions;
  final List<String>? customPermissions; // null = using role defaults

  AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.permissions,
    this.customPermissions,
  });

  bool can(String perm) => permissions.contains(perm);

  static List<String> effectivePermissions(String role, String? customPermissionsJson) {
    if (customPermissionsJson != null && customPermissionsJson.isNotEmpty) {
      try {
        final list = (jsonDecode(customPermissionsJson) as List).cast<String>();
        return list.where(Perm.all.contains).toList();
      } catch (_) {
        // fall through to role default on malformed data
      }
    }
    return RoleDefaults.sets[role] ?? const [];
  }

  factory AppUser.fromRow(Map<String, dynamic> row) {
    final customJson = row['custom_permissions'] as String?;
    return AppUser(
      id: row['id'] as String,
      username: row['username'] as String,
      fullName: row['full_name'] as String,
      role: row['role'] as String,
      isActive: (row['is_active'] as int) == 1,
      permissions: effectivePermissions(row['role'] as String, customJson),
      customPermissions: customJson != null ? (jsonDecode(customJson) as List).cast<String>() : null,
    );
  }
}

class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  static const _sessionKey = 'session_user_id';
  final _repo = BaseRepository('users');

  AppUser? _current;
  AppUser? get currentUser => _current;

  /// Creates a local admin/admin123 account the very first time the app
  /// runs with no users at all, so a shop can start working offline
  /// immediately instead of being blocked on a cloud sync that hasn't
  /// happened yet. This account syncs to the cloud like any other once
  /// the device goes online.
  Future<void> ensureDefaultAdmin() async {
    final all = await _repo.getAll();
    if (all.isNotEmpty) return;
    await _repo.insert({
      'username': 'admin',
      'full_name': 'Administrator',
      'password_hash': hashPassword('admin123'),
      'role': 'admin',
      'custom_permissions': null,
      'is_active': 1,
      'last_login': null,
    });
  }

  Future<String?> login(String username, String password) async {
    final rows = await _repo.getAll(
      where: 'LOWER(username) = ?',
      whereArgs: [username.trim().toLowerCase()],
    );
    if (rows.isEmpty) return 'Username not found.';
    final row = rows.first;
    if ((row['is_active'] as int) != 1) return 'This account has been deactivated.';
    if (!verifyPassword(password, row['password_hash'] as String)) return 'Incorrect password.';

    await _repo.update(row['id'] as String, {'last_login': DateTime.now().toUtc().toIso8601String()});
    _current = AppUser.fromRow(row);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, row['id'] as String);
    return null;
  }

  Future<void> logout() async {
    _current = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  /// Restores the session on app relaunch (no re-login needed every time
  /// the app is opened, matching normal mobile-app expectations).
  Future<AppUser?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_sessionKey);
    if (id == null) return null;
    final row = await _repo.getById(id);
    if (row == null || (row['is_active'] as int) != 1) {
      await prefs.remove(_sessionKey);
      return null;
    }
    _current = AppUser.fromRow(row);
    return _current;
  }
}
