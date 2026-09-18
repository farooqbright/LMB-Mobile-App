import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../core/network/api_exception.dart';
import '../models/auth_session.dart';
import '../services/auth_service.dart';

class ChangePasswordController extends ChangeNotifier {
  ChangePasswordController({
    required this.session,
    AuthService? authService,
  }) : _authService = authService ?? AuthService();

  final AuthSession session;
  final AuthService _authService;

  final formKey = GlobalKey<FormState>();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscureCurrent = true;
  bool obscureNew = true;
  bool obscureConfirm = true;
  bool isLoading = false;
  String? errorMessage;

  void toggleCurrentVisibility() {
    obscureCurrent = !obscureCurrent;
    notifyListeners();
  }

  void toggleNewVisibility() {
    obscureNew = !obscureNew;
    notifyListeners();
  }

  void toggleConfirmVisibility() {
    obscureConfirm = !obscureConfirm;
    notifyListeners();
  }

  void clearError() {
    if (errorMessage == null) return;
    errorMessage = null;
    notifyListeners();
  }

  String? validateCurrent(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.currentPasswordRequired;
    }
    return null;
  }

  String? validateNew(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.newPasswordRequired;
    }
    if (value.length < 8) {
      return AppStrings.newPasswordMin;
    }
    if (value == currentPasswordController.text) {
      return AppStrings.passwordMustDiffer;
    }
    return null;
  }

  String? validateConfirm(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.confirmPasswordRequired;
    }
    if (value != newPasswordController.text) {
      return AppStrings.passwordsDoNotMatch;
    }
    return null;
  }

  Future<bool> submit() async {
    if (isLoading) return false;

    errorMessage = null;
    final valid = formKey.currentState?.validate() ?? false;
    if (!valid) return false;

    isLoading = true;
    notifyListeners();

    try {
      await _authService.changePassword(
        session: session,
        currentPassword: currentPasswordController.text,
        password: newPasswordController.text,
        passwordConfirmation: confirmPasswordController.text,
      );
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
      return false;
    } catch (_) {
      errorMessage = 'Unable to update password. Please try again.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
