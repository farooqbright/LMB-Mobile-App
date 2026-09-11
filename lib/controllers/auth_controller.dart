import 'package:flutter/material.dart';

import '../models/login_credentials.dart';

class AuthController extends ChangeNotifier {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final hostController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  SchoolHostType hostType = SchoolHostType.subdomain;
  bool rememberMe = false;
  bool obscurePassword = true;

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

    return LoginCredentials(
      hostType: hostType,
      host: hostController.text.trim(),
      username: usernameController.text.trim(),
      password: passwordController.text,
      rememberMe: rememberMe,
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    hostController.dispose();
    super.dispose();
  }
}
