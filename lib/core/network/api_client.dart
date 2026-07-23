import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../exceptions/api_exception.dart';
import '../storage/token_storage.dart';

class ApiClient {
  ApiClient({
    http.Client? httpClient,
    TokenStorage? tokenStorage,
  })  : _httpClient = httpClient ?? http.Client(),
        _tokenStorage = tokenStorage ?? const TokenStorage();

  final http.Client _httpClient;
  final TokenStorage _tokenStorage;

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authenticated = false,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final headers = await _buildHeaders(authenticated: authenticated);
    return _execute(() => _httpClient.get(uri, headers: headers));
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authenticated = false,
    Object? body,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final headers = await _buildHeaders(authenticated: authenticated);
    return _execute(
      () => _httpClient.post(uri, headers: headers, body: _encodeBody(body)),
    );
  }

  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authenticated = false,
    Object? body,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final headers = await _buildHeaders(authenticated: authenticated);
    return _execute(
      () => _httpClient.put(uri, headers: headers, body: _encodeBody(body)),
    );
  }

  Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authenticated = false,
    Object? body,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final headers = await _buildHeaders(authenticated: authenticated);
    return _execute(
      () => _httpClient.patch(uri, headers: headers, body: _encodeBody(body)),
    );
  }

  Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authenticated = false,
    Object? body,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final headers = await _buildHeaders(authenticated: authenticated);
    return _execute(
      () => _httpClient.delete(uri, headers: headers, body: _encodeBody(body)),
    );
  }

  /// Runs a request, decodes the response, and turns every failure mode —
  /// HTTP error status, timeout, no connection, or anything unexpected —
  /// into the same `ApiException` type with a clean, user-safe message.
  /// Screens only ever need to handle one exception type.
  Future<dynamic> _execute(
    Future<http.Response> Function() sendRequest,
  ) async {
    try {
      final response = await sendRequest().timeout(AppConfig.requestTimeout);
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        message:
            'The request took too long to respond. Please check your connection and try again.',
      );
    } on SocketException {
      throw const ApiException(
        message:
            'Unable to reach the server. Please check your connection and try again.',
      );
    } on http.ClientException {
      throw const ApiException(
        message: 'A network error occurred. Please try again.',
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Unexpected network error: $error');
      }
      throw const ApiException(
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  Uri _buildUri(String path, Map<String, dynamic>? queryParameters) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/$normalizedPath');
    if (queryParameters == null || queryParameters.isEmpty) return uri;
    final qp = <String, String>{};
    queryParameters.forEach((key, value) {
      qp[key] = value == null ? '' : value.toString();
    });
    return uri.replace(queryParameters: qp);
  }

  Future<Map<String, String>> _buildHeaders({
    required bool authenticated,
    Map<String, String>? extraHeaders,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (extraHeaders != null) ...extraHeaders,
    };

    if (authenticated) {
      final token = await _tokenStorage.readToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Object? _encodeBody(Object? body) {
    if (body == null) return null;
    if (body is String) return body;
    return jsonEncode(body);
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    dynamic decoded;

    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (error) {
        if (kDebugMode) {
          debugPrint('Failed to decode response: $error');
        }
        decoded = response.body;
      }
    }

    if (statusCode >= 200 && statusCode < 300) {
      return decoded;
    }

    final message = _extractErrorMessage(decoded) ??
        'Request failed with status $statusCode';

    throw ApiException(
      statusCode: statusCode,
      message: message,
      details: decoded,
    );
  }

  String? _extractErrorMessage(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      for (final key in ['message', 'error', 'errors']) {
        final value = decoded[key];
        if (value is String && value.isNotEmpty) {
          return value;
        }
        if (value is List) {
          for (final element in value) {
            if (element is String && element.isNotEmpty) {
              return element;
            }
          }
        }
        if (value is Map<String, dynamic>) {
          final nested = _extractErrorMessage(value);
          if (nested != null) return nested;
        }
      }
    }
    return null;
  }
}
