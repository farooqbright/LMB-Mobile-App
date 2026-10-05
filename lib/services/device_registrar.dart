import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/auth_session.dart';
import 'auth_service.dart';
import 'push_notification_service.dart';
import 'session_store.dart';

class DeviceRegistrar {
  DeviceRegistrar({
    AuthService? authService,
    PushNotificationService? push,
    this.enabled = true,
  })  : _authService = authService ?? AuthService(),
        _push = push ?? PushNotificationService.instance;

  static DeviceRegistrar? debugInstance;

  factory DeviceRegistrar.instance() =>
      debugInstance ?? DeviceRegistrar();

  final AuthService _authService;
  final PushNotificationService _push;
  final bool enabled;
  bool _listening = false;
  int _attempts = 0;
  Timer? _retry;

  Future<void> sync(AuthSession session) async {
    if (!enabled) return;
    await _push.initialize();
    _listen();
    final registered = await _registerIfPossible(session);
    if (!registered) {
      _scheduleRetry();
    }
  }

  Future<void> unregister(AuthSession? session) async {
    if (!enabled || session == null) return;
    _retry?.cancel();
    _attempts = 0;
    try {
      await _authService.logout(
        session,
        deviceId: await _push.deviceId(),
      );
    } catch (_) {}
  }

  Future<bool> _registerIfPossible(AuthSession session) async {
    try {
      await _push.initialize();
      final token = await _push.token();
      if (token == null || token.isEmpty) {
        debugPrint('Device register skipped: FCM token is not ready yet.');
        return false;
      }

      await _authService.registerDevice(
        session,
        deviceId: await _push.deviceId(),
        token: token,
        platform: _push.platformName(),
      );
      _attempts = 0;
      _retry?.cancel();
      return true;
    } catch (error) {
      debugPrint('Device register failed: $error');
      return false;
    }
  }

  void _listen() {
    if (_listening || !_push.isReady) return;
    _listening = true;
    _push.listenForTokenRefresh(_refreshToken);
  }

  void _scheduleRetry() {
    if (_attempts >= 6) return;
    _attempts++;
    _retry?.cancel();
    _retry = Timer(Duration(seconds: _attempts * 2), () {
      final current = SessionStore.instance.current;
      if (current == null) return;
      sync(current);
    });
  }

  Future<void> _refreshToken(String token) async {
    final current = SessionStore.instance.current;
    if (current == null || token.isEmpty) return;
    try {
      await _authService.registerDevice(
        current,
        deviceId: await _push.deviceId(),
        token: token,
        platform: _push.platformName(),
      );
      _attempts = 0;
      _retry?.cancel();
    } catch (error) {
      debugPrint('Device token refresh failed: $error');
    }
  }
}
