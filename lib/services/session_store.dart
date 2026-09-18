import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_session.dart';

class SessionStore {
  SessionStore._();

  static final SessionStore instance = SessionStore._();

  static const _key = 'auth_session';

  AuthSession? current;

  Future<void> save(AuthSession session) async {
    current = session;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(session.toJson()));
    } catch (_) {
      // Keep the in-memory session even if local storage is unavailable.
    }
  }

  Future<void> update(AuthSession session) async {
    current = session;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(session.toJson()));
    } catch (_) {}
  }

  Future<AuthSession?> restore() async {
    if (current != null) return current;

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      current = AuthSession.fromJson(Map<String, dynamic>.from(decoded));
      return current;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    current = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}
