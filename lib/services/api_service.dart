import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../config/constants.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class ApiService {
  final StorageService _storageService;
  final http.Client _client;

  ApiService({
    required StorageService storageService,
    http.Client? client,
  })  : _storageService = storageService,
        _client = client ?? http.Client();

  String get _baseUrl => Env.apiBaseUrl;

  Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await _storageService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint').replace(
      queryParameters: queryParams,
    );

    return _executeRequest(() => _client
        .get(uri, headers: _syncHeaders)
        .timeout(AppConstants.apiTimeout),
      requiresAuth: requiresAuth,
      uri: uri,
    );
  }

  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');

    return _executeRequest(() => _client
        .post(
          uri,
          headers: _syncHeaders,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(AppConstants.apiTimeout),
      requiresAuth: requiresAuth,
      uri: uri,
    );
  }

  Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');

    return _executeRequest(() => _client
        .put(
          uri,
          headers: _syncHeaders,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(AppConstants.apiTimeout),
      requiresAuth: requiresAuth,
      uri: uri,
    );
  }

  Future<dynamic> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');

    return _executeRequest(() => _client
        .delete(uri, headers: _syncHeaders)
        .timeout(AppConstants.apiTimeout),
      requiresAuth: requiresAuth,
      uri: uri,
    );
  }

  Map<String, String> _syncHeaders = {};

  Future<dynamic> _executeRequest(
    Future<http.Response> Function() request, {
    required bool requiresAuth,
    required Uri uri,
  }) async {
    _syncHeaders = await _getHeaders(requiresAuth: requiresAuth);
    try {
      final response = await request();
      return _handleResponse(response);
    } on SocketException {
      throw NetworkException(
        'No internet connection. Please check your network and try again.',
      );
    } on TimeoutException {
      throw NetworkException(
        'Request timed out. Please try again.',
      );
    } on http.ClientException {
      throw NetworkException(
        'Connection failed. Please try again.',
      );
    }
  }

  Future<dynamic> multipartPost(
    String endpoint, {
    required String filePath,
    String fileField = 'file',
    Map<String, String>? fields,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');

    try {
      final request = http.MultipartRequest('POST', uri);

      final token = await _storageService.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      request.files.add(
        await http.MultipartFile.fromPath(fileField, filePath),
      );
      if (fields != null) request.fields.addAll(fields);

      final streamedResponse =
          await request.send().timeout(AppConstants.apiTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException(
        'No internet connection. Please check your network and try again.',
      );
    } on TimeoutException {
      throw NetworkException('Request timed out. Please try again.');
    } on http.ClientException {
      throw NetworkException('Connection failed. Please try again.');
    }
  }

  dynamic _handleResponse(http.Response response) {
    dynamic body;

    // Strip any non-JSON prefix (e.g. server warnings) before parsing
    var rawBody = response.body;
    final jsonStart = rawBody.indexOf('{');
    final arrayStart = rawBody.indexOf('[');
    int start = -1;
    if (jsonStart >= 0 && arrayStart >= 0) {
      start = jsonStart < arrayStart ? jsonStart : arrayStart;
    } else if (jsonStart >= 0) {
      start = jsonStart;
    } else if (arrayStart >= 0) {
      start = arrayStart;
    }
    if (start > 0) rawBody = rawBody.substring(start);

    try {
      body = jsonDecode(rawBody);
    } catch (_) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return null;
      }
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Unexpected server response',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: _extractErrorMessage(body),
    );
  }

  String _extractErrorMessage(dynamic body) {
    if (body is! Map) return 'Something went wrong';

    // WordPress-style: { "message": "...", "errors": { "field": ["msg"] } }
    if (body.containsKey('errors') && body['errors'] is Map) {
      final errors = body['errors'] as Map;
      final messages = <String>[];
      for (final fieldErrors in errors.values) {
        if (fieldErrors is List) {
          messages.addAll(fieldErrors.map((e) => e.toString()));
        } else if (fieldErrors is String) {
          messages.add(fieldErrors);
        }
      }
      if (messages.isNotEmpty) return messages.join('\n');
    }

    // Simple: { "message": "..." }
    if (body.containsKey('message') && body['message'] is String) {
      return body['message'] as String;
    }

    // WP REST: { "data": { "message": "..." } }
    if (body.containsKey('data') && body['data'] is Map) {
      final data = body['data'] as Map;
      if (data.containsKey('message')) return data['message'].toString();
    }

    return 'Something went wrong';
  }
}
