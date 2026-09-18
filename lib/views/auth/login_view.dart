import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../controllers/auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/login_credentials.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final AuthController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AuthController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onSignIn() async {
    final session = await _controller.login();
    if (!mounted || session == null) return;

    Navigator.of(context).pushReplacementNamed(
      AppRoutes.dashboardFor(session),
      arguments: session,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              AppColors.navy,
              Color(0xFF1E40AF),
              AppColors.navyDeep,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) {
                    return Container(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x330F1D4A),
                            blurRadius: 28,
                            offset: Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _controller.formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              AppStrings.appName,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              AppStrings.signInSubtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 28),
                            const Text(
                              AppStrings.schoolHostLabel,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<SchoolHostType>(
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                    title: const Text(AppStrings.subdomainOption),
                                    value: SchoolHostType.subdomain,
                                    groupValue: _controller.hostType,
                                    activeColor: AppColors.primary,
                                    onChanged: _controller.isLoading
                                        ? null
                                        : _controller.setHostType,
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<SchoolHostType>(
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                    title: const Text(AppStrings.domainOption),
                                    value: SchoolHostType.domain,
                                    groupValue: _controller.hostType,
                                    activeColor: AppColors.primary,
                                    onChanged: _controller.isLoading
                                        ? null
                                        : _controller.setHostType,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              _controller.hostLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              key: ValueKey(_controller.hostType),
                              controller: _controller.hostController,
                              enabled: !_controller.isLoading,
                              keyboardType: TextInputType.url,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) => _controller.clearError(),
                              validator: _controller.validateHost,
                              decoration: InputDecoration(
                                hintText: _controller.hostHint,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              AppStrings.usernameLabel,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _controller.usernameController,
                              enabled: !_controller.isLoading,
                              keyboardType: TextInputType.text,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) => _controller.clearError(),
                              validator: _controller.validateUsername,
                              decoration: const InputDecoration(
                                hintText: AppStrings.usernameHint,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              AppStrings.passwordLabel,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _controller.passwordController,
                              enabled: !_controller.isLoading,
                              obscureText: _controller.obscurePassword,
                              textInputAction: TextInputAction.done,
                              onChanged: (_) => _controller.clearError(),
                              onFieldSubmitted: (_) {
                                if (!_controller.isLoading) {
                                  _onSignIn();
                                }
                              },
                              validator: _controller.validatePassword,
                              decoration: InputDecoration(
                                hintText: AppStrings.passwordHint,
                                suffixIcon: IconButton(
                                  onPressed: _controller.togglePasswordVisibility,
                                  icon: Icon(
                                    _controller.obscurePassword
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
                              onPressed: _controller.isLoading
                                  ? () {}
                                  : _onSignIn,
                              child: _controller.isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(AppStrings.signIn),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
