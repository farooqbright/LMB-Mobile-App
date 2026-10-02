import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lmssystem/core/network/api_client.dart';
import 'package:lmssystem/models/auth_session.dart';
import 'package:lmssystem/services/auth_service.dart';

AuthSession _parentSession() {
  return AuthSession.fromJson({
    'token': 'parent.token',
    'token_type': 'Bearer',
    'type': 'parent',
    'school': {'id': '1', 'name': 'SLS', 'domain': 'sls.localhost'},
    'user': {
      'id': 9,
      'name': 'Ali',
      'last_name': 'Khan',
      'email': 'parent@example.com',
      'username': '35202-1234567-1',
      'roles': ['Parent'],
    },
    'profile': {
      'type': 'parent',
      'guardian_id': 4,
      'full_name': 'Ali Khan',
    },
  });
}

void main() {
  test('registers the device token after login', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode({
          'status': 'success',
          'message': 'Device registered.',
          'data': {'device_id': 'phone-1', 'platform': 'android'},
        }),
        200,
      );
    });

    await AuthService(client: ApiClient(httpClient: client)).registerDevice(
      _parentSession(),
      deviceId: 'phone-1',
      token: 'fcm-token-aaa',
      platform: 'android',
    );

    expect(captured.method, 'POST');
    expect(captured.url.path, contains('/mobile/auth/device'));
    expect(captured.headers['Authorization'], 'Bearer parent.token');
    expect(jsonDecode(captured.body), {
      'domain': 'sls.localhost',
      'device_id': 'phone-1',
      'token': 'fcm-token-aaa',
      'platform': 'android',
    });
  });

  test('logs out and sends the same device id', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode({
          'status': 'success',
          'message': 'Logged out.',
          'data': null,
        }),
        200,
      );
    });

    await AuthService(client: ApiClient(httpClient: client)).logout(
      _parentSession(),
      deviceId: 'phone-1',
    );

    expect(captured.method, 'POST');
    expect(captured.url.path, contains('/mobile/auth/logout'));
    expect(jsonDecode(captured.body), {
      'domain': 'sls.localhost',
      'device_id': 'phone-1',
    });
  });
}
