import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/auth_session.dart';
import '../../services/session_store.dart';

class DashboardAction {
  const DashboardAction({
    required this.icon,
    required this.label,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final Color tint;
}

class DashboardShell extends StatelessWidget {
  const DashboardShell({
    super.key,
    required this.session,
    required this.roleLabel,
    required this.subtitle,
    required this.details,
    required this.actions,
  });

  final AuthSession session;
  final String roleLabel;
  final String subtitle;
  final List<DashboardDetail> details;
  final List<DashboardAction> actions;

  Future<void> _logout(BuildContext context) async {
    await SessionStore.instance.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.navy,
        content: Text('$label will be available in the next update.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.paddingOf(context).top + 16,
                8,
                24,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.navy, AppColors.navyDeep],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          session.schoolName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: AppStrings.signOut,
                        onPressed: () => _logout(context),
                        icon: const Icon(Icons.logout_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      roleLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Welcome, ${session.welcomeName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < details.length; i++) ...[
                          if (i > 0) const Divider(height: 22),
                          _DetailRow(detail: details[i]),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    AppStrings.quickAccess,
                    style: TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: [
                      for (final action in actions)
                        Material(
                          color: action.tint.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _comingSoon(context, action.label),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(action.icon, color: action.tint, size: 26),
                                  const Spacer(),
                                  Text(
                                    action.label,
                                    style: TextStyle(
                                      color: action.tint,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardDetail {
  const DashboardDetail({required this.label, required this.value});

  final String label;
  final String value;
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.detail});

  final DashboardDetail detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            detail.label,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            detail.value,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
