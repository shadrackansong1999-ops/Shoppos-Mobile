import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Simple salted SHA-256 hash, same scheme used across the app (license
/// unlock password, user accounts) and compatible in spirit with the
/// desktop app's core/auth.py `salt:hash` format.
String hashPassword(String password) {
  final rnd = Random.secure();
  final saltBytes = List<int>.generate(16, (_) => rnd.nextInt(256));
  final salt = saltBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  final hash = sha256.convert(utf8.encode(salt + password)).toString();
  return '$salt:$hash';
}

bool verifyPassword(String password, String stored) {
  final parts = stored.split(':');
  if (parts.length != 2) return false;
  final hash = sha256.convert(utf8.encode(parts[0] + password)).toString();
  return hash == parts[1];
}
