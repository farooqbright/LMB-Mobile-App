import 'package:flutter/material.dart';

import '../core/constants/api_config.dart';
import '../core/network/api_exception.dart';
import '../models/auth_session.dart';
import '../models/login_credentials.dart';
import '../services/auth_service.dart';
import '../services/session_store.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    AuthService? authService,
    SessionStore? sessionStore,
  })  : _authService = authService ?? AuthService(),
        _sessionStore = sessionStore ?? SessionStore.instance;

  final AuthService _authService;
  final SessionStore _sessionStore;

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final hostController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  SchoolHostType hostType = SchoolHostType.subdomain;
  bool rememberMe = false;
  bool obscurePassword = true;
  bool isLoading = false;
  String? errorMessage;

  bool get isSubdomain => hostType == SchoolHostType.subdomain;

  String get hostLabel => isSubdomain ? 'SubDomain' : 'Domain';

  String get hostHint =>
      isSubdomain ? 'Enter subdomain, e.g. sls' : 'Enter domain, e.g. school.com';

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void toggleRememberMe(bool? value) {
    rememberMe = value ?? false;
    notifyListeners();
  }

  void setHostType(SchoolHostType? type) {
    if (type == null || hostType == type) return;
    hostType = type;
    hostController.clear();
    notifyListeners();
  }

  void clearError() {
    if (errorMessage == null) return;
    errorMessage = null;
    notifyListeners();
  }

  String? validateHost(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return '$hostLabel is required';
    }
    if (isSubdomain) {
      final subdomain = RegExp(r'^[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$');
      if (!subdomain.hasMatch(text)) {
        return 'Enter a valid subdomain';
      }
    } else {
      final domain = RegExp(
        r'^[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$',
      );
      if (!domain.hasMatch(text)) {
        return 'Enter a valid domain';
      }
    }
    return null;
  }

  String? validateUsername(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Username is required';
    }

    final isEmail = text.contains('@') && text.contains('.');
    final isCnic = RegExp(r'^\d{5}-\d{7}-\d$').hasMatch(text);
    if (!isEmail && !isCnic) {
      return 'Enter your email or CNIC';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  LoginCredentials? submit() {
    final valid = formKey.currentState?.validate() ?? false;
    if (!valid) {
      return null;
    }

    final host = hostController.text.trim();

    return LoginCredentials(
      hostType: hostType,
      host: host,
      schoolDomain: ApiConfig.schoolDomain(hostType: hostType, host: host),
      username: usernameController.text.trim(),
      password: passwordController.text,
      rememberMe: rememberMe,
    );
  }

  Future<AuthSession?> login() async {
    if (isLoading) return null;

    errorMessage = null;
    final credentials = submit();
    if (credentials == null) return null;

    isLoading = true;
    notifyListeners();

    try {
      final session = await _authService.login(credentials);
      await _sessionStore.save(session, persist: rememberMe);
      return session;
    } on ApiException catch (error) {
      errorMessage = error.message;
      return null;
    } catch (_) {
      errorMessage = 'Unable to sign in. Please try again.';
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    hostController.dispose();
    super.dispose();
  }
}
