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
  }) async {
    final uri = ApiConfig.uri(endpoint);

    try {
      final response = await _http
          .post(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body ?? const {}),
          )
          .timeout(ApiConfig.timeout);

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
