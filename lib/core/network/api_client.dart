import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../constants/api_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) {
    return _execute(
      () => _http.post(
        ApiConfig.uri(endpoint),
        headers: _headers(token: token, jsonBody: true),
        body: jsonEncode(body ?? const {}),
      ),
    );
  }

  Future<Map<String, dynamic>> get(
    String endpoint, {
    String? token,
    Map<String, String>? query,
  }) {
    var uri = ApiConfig.uri(endpoint);
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          ...query,
        },
      );
    }

    return _execute(
      () => _http.get(uri, headers: _headers(token: token)),
    );
  }

  Map<String, String> _headers({String? token, bool jsonBody = false}) {
    return {
      'Accept': 'application/json',
      if (jsonBody) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> _execute(
    Future<http.Response> Function() send,
  ) async {
    try {
      final response = await send().timeout(ApiConfig.timeout);
      return _decode(response);
    } on TimeoutException {
      throw const ApiException('The server took too long to respond.');
    } on SocketException {
      throw const ApiException(
        'Cannot reach the school server. Check the domain and your connection.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Cannot reach the school server. Check the domain and your connection.',
      );
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> json = {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        json = decoded;
      }
    } catch (_) {
      throw ApiException(
        'Unexpected response from the server.',
        statusCode: response.statusCode,
      );
    }

    final message = json['message'] is String && (json['message'] as String).isNotEmpty
        ? json['message'] as String
        : 'Something went wrong.';
    final status = json['status'];
    final ok = response.statusCode >= 200 &&
        response.statusCode < 300 &&
        status != 'error';

    if (!ok) {
      throw ApiException(message, statusCode: response.statusCode);
    }

    return json;
  }
}
