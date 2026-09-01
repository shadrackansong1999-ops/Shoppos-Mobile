import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';

/// Same trial/lock model as the desktop app's core/license.py, kept
/// per-device (a shop might trial the phone app on one staff member's
/// device before buying seats for the rest). Mode is 'unset' | 'trial' |
/// 'unrestricted'. A tamper check (HMAC over the row) fails safe to
/// locked if the license_state row was edited outside the app.
class LicenseStatus {
  final bool configured;
  final String mode;
  final bool locked;
  final int? daysRemaining;
  final bool tampered;
  LicenseStatus({
    required this.configured,
    required this.mode,
    required this.locked,
    this.daysRemaining,
    this.tampered = false,
  });
}

class LicenseService {
  LicenseService._internal();
  static final LicenseService instance = LicenseService._internal();

  static const _macSecret = 'ShopPOS-Mobile-license-integrity-v1';

  String _hashPassword(String password) {
    final salt = DateTime.now().microsecondsSinceEpoch.toRadixString(16) +
        password.hashCode.toRadixString(16);
    final hash = sha256.convert(utf8.encode(salt + password)).toString();
    return '$salt:$hash';
  }

  bool _verifyPassword(String password, String stored) {
    final parts = stored.split(':');
    if (parts.length != 2) return false;
    final hash = sha256.convert(utf8.encode(parts[0] + password)).toString();
    return hash == parts[1];
  }

  String _computeMac(Map<String, dynamic> row) {
    final payload = [
      row['mode'] ?? '',
      row['trial_days']?.toString() ?? '',
      row['activated_at'] ?? '',
      row['unlock_password_hash'] ?? '',
      row['unlocked_at'] ?? '',
    ].join('|');
    final mac = Hmac(sha256, utf8.encode(_macSecret));
    return mac.convert(utf8.encode(payload)).toString();
  }

  Future<Map<String, dynamic>?> _getRow() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('license_state', where: 'id = 1');
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> _saveRow(Map<String, dynamic> fields) async {
    final db = await DatabaseHelper.instance.database;
    final mac = _computeMac(fields);
    await db.insert(
      'license_state',
      {...fields, 'id': 1, 'integrity_mac': mac},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> isConfigured() async {
    final row = await _getRow();
    return row != null && (row['mode'] == 'trial' || row['mode'] == 'unrestricted');
  }

  Future<String?> setupTrial({required int trialDays, required String unlockPassword}) async {
    if (await isConfigured()) return 'Already configured on this device.';
    if (trialDays <= 0) return 'Trial duration must be at least 1 day.';
    if (unlockPassword.length < 4) return 'Unlock password must be at least 4 characters.';
    await _saveRow({
      'mode': 'trial',
      'trial_days': trialDays,
      'activated_at': DateTime.now().toUtc().toIso8601String(),
      'unlock_password_hash': _hashPassword(unlockPassword),
      'unlocked_at': null,
    });
    return null; // null = success
  }

  Future<String?> setupUnrestricted() async {
    if (await isConfigured()) return 'Already configured on this device.';
    await _saveRow({
      'mode': 'unrestricted',
      'trial_days': null,
      'activated_at': DateTime.now().toUtc().toIso8601String(),
      'unlock_password_hash': null,
      'unlocked_at': null,
    });
    return null;
  }

  Future<LicenseStatus> getStatus() async {
    final row = await _getRow();
    if (row == null || (row['mode'] != 'trial' && row['mode'] != 'unrestricted')) {
      return LicenseStatus(configured: false, mode: 'unset', locked: false);
    }

    final tampered = _computeMac(row) != row['integrity_mac'];
    if (tampered) {
      return LicenseStatus(configured: true, mode: row['mode'] as String, locked: true, tampered: true);
    }

    if (row['mode'] == 'unrestricted') {
      return LicenseStatus(configured: true, mode: 'unrestricted', locked: false);
    }

    final started = DateTime.parse(row['activated_at'] as String);
    final days = row['trial_days'] as int;
    final expires = started.add(Duration(days: days));
    final now = DateTime.now().toUtc();
    final remaining = expires.difference(now);
    final daysRemaining = remaining.isNegative ? 0 : remaining.inHours ~/ 24 + 1;
    return LicenseStatus(
      configured: true,
      mode: 'trial',
      locked: now.isAfter(expires),
      daysRemaining: daysRemaining,
    );
  }

  Future<String?> unlock(String password) async {
    final row = await _getRow();
    if (row == null || row['mode'] != 'trial') return 'No active trial to unlock.';
    final hash = row['unlock_password_hash'] as String?;
    if (hash == null || !_verifyPassword(password, hash)) return 'Incorrect unlock password.';
    await _saveRow({
      'mode': 'unrestricted',
      'trial_days': row['trial_days'],
      'activated_at': row['activated_at'],
      'unlock_password_hash': row['unlock_password_hash'],
      'unlocked_at': DateTime.now().toUtc().toIso8601String(),
    });
    return null;
  }
}
