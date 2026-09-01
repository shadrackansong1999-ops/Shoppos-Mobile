import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around the cloud API. The base URL is configurable from
/// Settings (each shop points its phones at its own server - the same
/// Flask backend the desktop app talks to, extended with /api/sync/*
/// and /api/mobile/* routes), so nothing here is hard-coded to one
/// deployment.
class ApiClient {
  ApiClient._internal();
  static final ApiClient instance = ApiClient._internal();

  static const _prefKey = 'server_base_url';
  String? _baseUrl;

  Future<String?> getBaseUrl() async {
    if (_baseUrl != null) return _baseUrl;
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_prefKey);
    return _baseUrl;
  }

  Future<void> setBaseUrl(String url) async {
    final cleaned = url.trim().replaceAll(RegExp(r'/+$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, cleaned);
    _baseUrl = cleaned;
  }

  Future<bool> get isConfigured async => (await getBaseUrl())?.isNotEmpty == true;

  Uri _uri(String path, [Map<String, String>? query]) {
    if (_baseUrl == null || _baseUrl!.isEmpty) {
      throw StateError('Server address not set. Configure it in Settings first.');
    }
    return Uri.parse('$_baseUrl$path').replace(queryParameters: query);
  }

  Future<ApiResult> get(String path, {Map<String, String>? query}) async {
    try {
      final res = await http.get(_uri(path, query)).timeout(const Duration(seconds: 12));
      return ApiResult.fromResponse(res);
    } catch (e) {
      return ApiResult.networkError(e.toString());
    }
  }

  Future<ApiResult> post(String path, Map<String, dynamic> body) async {
    try {
      final res = await http
          .post(_uri(path), headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
          .timeout(const Duration(seconds: 20));
      return ApiResult.fromResponse(res);
    } catch (e) {
      return ApiResult.networkError(e.toString());
    }
  }

  Future<ApiResult> put(String path, Map<String, dynamic> body) async {
    try {
      final res = await http
          .put(_uri(path), headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
          .timeout(const Duration(seconds: 20));
      return ApiResult.fromResponse(res);
    } catch (e) {
      return ApiResult.networkError(e.toString());
    }
  }

  /// Quick reachability check for the "Test Connection" button in Settings.
  Future<bool> ping() async {
    final r = await get('/api/health');
    return r.ok;
  }
}

class ApiResult {
  final bool ok;
  final int? statusCode;
  final dynamic data;
  final String? error;

  ApiResult({required this.ok, this.statusCode, this.data, this.error});

  factory ApiResult.fromResponse(http.Response res) {
    Map<String, dynamic>? parsed;
    try {
      parsed = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      parsed = null;
    }
    final serverOk = parsed?['ok'] == true;
    if (res.statusCode >= 200 && res.statusCode < 300 && serverOk) {
      return ApiResult(ok: true, statusCode: res.statusCode, data: parsed?['data']);
    }
    return ApiResult(
      ok: false,
      statusCode: res.statusCode,
      error: (parsed?['error'] as String?) ?? 'Server error (${res.statusCode})',
    );
  }

  factory ApiResult.networkError(String message) =>
      ApiResult(ok: false, error: 'Could not reach the server: $message');
}
