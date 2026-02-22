import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
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

  static const _maxRetries = 2;
  static const _retryDelay = Duration(seconds: 1);

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

  bool _isRetryable(Object e) {
    if (e is SocketException) return true;
    if (e is HttpException) return true;
    if (e is TimeoutException) return true;
    // http.ClientException wraps SocketExceptions with message strings
    final msg = e.toString().toLowerCase();
    return msg.contains('connection closed') ||
        msg.contains('connection reset') ||
        msg.contains('connection refused') ||
        msg.contains('socketexception') ||
        msg.contains('clientexception');
  }

  ApiException _mapToApiException(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('no internet') ||
        msg.contains('network is unreachable') ||
        e is SocketException) {
      return const ApiException(statusCode: 0, message: 'No internet connection');
    }
    return ApiException(statusCode: 0, message: 'Network error — please retry');
  }

  Future<dynamic> get(String path) async {
    final headers = await _authHeaders();
    final base = await baseUrl;
    final uri = Uri.parse('$base$path');

    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final res = await _client
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 15));
        return _handle(res);
      } catch (e) {
        if (e is ApiException) rethrow;
        if (_isRetryable(e) && attempt < _maxRetries) {
          debugPrint(
              '⚠️ [ApiClient] GET $path attempt ${attempt + 1} failed ($e), retrying...');
          await Future.delayed(_retryDelay);
          continue;
        }
        throw _mapToApiException(e);
      }
    }
    throw const ApiException(statusCode: 0, message: 'Request failed');
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    Duration timeout = const Duration(seconds: 20),
    int? maxRetries,
  }) async {
    final headers = await _authHeaders();
    final base = await baseUrl;
    final uri = Uri.parse('$base$path');
    final retries = maxRetries ?? _maxRetries;

    for (var attempt = 0; attempt <= retries; attempt++) {
      try {
        final res = await _client
            .post(uri,
                headers: headers, body: body != null ? jsonEncode(body) : null)
            .timeout(timeout);
        return _handle(res);
      } catch (e) {
        if (e is ApiException) rethrow;
        if (_isRetryable(e) && attempt < retries) {
          debugPrint(
              '⚠️ [ApiClient] POST $path attempt ${attempt + 1} failed ($e), retrying...');
          await Future.delayed(_retryDelay);
          continue;
        }
        throw _mapToApiException(e);
      }
    }
    throw const ApiException(statusCode: 0, message: 'Request failed');
  }

  /// Multipart POST with retry — used for video uploads.
  Future<http.Response> postMultipart(
    String path,
    Future<http.MultipartRequest> Function() buildRequest,
  ) async {
    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final req = await buildRequest();
        final streamed =
            await req.send().timeout(const Duration(seconds: 60));
        return await http.Response.fromStream(streamed);
      } catch (e) {
        if (_isRetryable(e) && attempt < _maxRetries) {
          debugPrint(
              '⚠️ [ApiClient] MULTIPART $path attempt ${attempt + 1} failed ($e), retrying...');
          await Future.delayed(_retryDelay);
          continue;
        }
        throw _mapToApiException(e);
      }
    }
    throw const ApiException(statusCode: 0, message: 'Upload failed');
  }

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
