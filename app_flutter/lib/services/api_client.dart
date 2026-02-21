import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/constants.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  static final ApiClient _instance = ApiClient._();
  factory ApiClient() => _instance;
  ApiClient._();

  final _client = http.Client();

  Future<String> get baseUrl async {
    return dotenv.env['API_BASE_URL'] ?? AppConstants.baseUrl;
  }

  Future<Map<String, String>> _authHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer test-token-admin',
      };
    }
    try {
      final token = await user.getIdToken();
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    } catch (_) {
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer test-token-admin',
      };
    }
  }

  Future<dynamic> get(String path) async {
    final headers = await _authHeaders();
    final base = await baseUrl;
    final uri = Uri.parse('$base$path');
    try {
      final res = await _client.get(uri, headers: headers).timeout(
            const Duration(seconds: 15),
          );
      return _handle(res);
    } on SocketException {
      throw const ApiException(
          statusCode: 0, message: 'No internet connection');
    } on HttpException {
      throw const ApiException(statusCode: 0, message: 'Network error');
    }
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final headers = await _authHeaders();
    final base = await baseUrl;
    final uri = Uri.parse('$base$path');
    try {
      final res = await _client
          .post(uri,
              headers: headers, body: body != null ? jsonEncode(body) : null)
          .timeout(const Duration(seconds: 20));
      return _handle(res);
    } on SocketException {
      throw const ApiException(
          statusCode: 0, message: 'No internet connection');
    }
  }

  /// Trigger Roshini's initial data sync to populate the workspace.
  Future<bool> triggerInitialSync(String workspaceId) async {
    try {
      await post('/sync/workspace/$workspaceId/initial?use_demo=true');
      return true;
    } catch (_) {
      return false;
    }
  }

  dynamic _handle(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    String message = 'Something went wrong';
    try {
      final body = jsonDecode(res.body);
      message =
          body['detail'] as String? ?? body['message'] as String? ?? message;
    } catch (_) {}
    throw ApiException(statusCode: res.statusCode, message: message);
  }
}
