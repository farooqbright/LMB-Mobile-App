import 'package:flutter/material.dart';

import '../../controllers/change_password_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/auth_session.dart';
import '../../services/auth_service.dart';

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({
    super.key,
    required this.session,
    this.authService,
  });

  final AuthSession session;
  final AuthService? authService;

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  late final ChangePasswordController _controller = ChangePasswordController(
    session: widget.session,
    authService: widget.authService,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    final updated = await _controller.submit();
    if (!mounted || !updated) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.navy,
        content: Text(AppStrings.passwordUpdated),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.changePassword),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Form(
                key: _controller.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      AppStrings.currentPasswordLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _controller.currentPasswordController,
                      enabled: !_controller.isLoading,
                      obscureText: _controller.obscureCurrent,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => _controller.clearError(),
                      validator: _controller.validateCurrent,
                      decoration: InputDecoration(
                        hintText: AppStrings.passwordHint,
                        suffixIcon: IconButton(
                          onPressed: _controller.toggleCurrentVisibility,
                          icon: Icon(
                            _controller.obscureCurrent
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      AppStrings.newPasswordLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _controller.newPasswordController,
                      enabled: !_controller.isLoading,
                      obscureText: _controller.obscureNew,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => _controller.clearError(),
                      validator: _controller.validateNew,
                      decoration: InputDecoration(
                        hintText: AppStrings.passwordHint,
                        suffixIcon: IconButton(
                          onPressed: _controller.toggleNewVisibility,
                          icon: Icon(
                            _controller.obscureNew
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      AppStrings.confirmPasswordLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _controller.confirmPasswordController,
                      enabled: !_controller.isLoading,
                      obscureText: _controller.obscureConfirm,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => _controller.clearError(),
                      onFieldSubmitted: (_) {
                        if (!_controller.isLoading) {
                          _onSubmit();
                        }
                      },
                      validator: _controller.validateConfirm,
                      decoration: InputDecoration(
                        hintText: AppStrings.passwordHint,
                        suffixIcon: IconButton(
                          onPressed: _controller.toggleConfirmVisibility,
                          icon: Icon(
                            _controller.obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ),
                    if (_controller.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.errorSoft,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          _controller.errorMessage!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _controller.isLoading ? () {} : _onSubmit,
                      child: _controller.isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text(AppStrings.updatePassword),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
