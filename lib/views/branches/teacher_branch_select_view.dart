import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/auth_session.dart';
import '../../services/session_store.dart';
import '../widgets/school_logo.dart';

class TeacherBranchSelectView extends StatelessWidget {
  const TeacherBranchSelectView({super.key, required this.session});

  final AuthSession session;

  Future<void> _select(BuildContext context, TeacherBranch branch) async {
    final updated = session.withBranch(branch);
    await SessionStore.instance.update(updated);
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.teacherDashboard,
      (_) => false,
      arguments: updated,
    );
  }

  Future<void> _logout(BuildContext context) async {
    await SessionStore.instance.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final branches = session.teacherBranches;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.paddingOf(context).top + 16,
              12,
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
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _logout(context),
                    child: const Text(
                      AppStrings.signOut,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SchoolLogo(
                  name: session.schoolName,
                  logoUrl: session.schoolLogoUrl,
                  size: 56,
                ),
                const SizedBox(height: 12),
                Text(
                  session.schoolName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  AppStrings.selectBranch,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              itemCount: branches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final branch = branches[index];
                return _BranchCard(
                  branch: branch,
                  selected: session.selectedBranchId == branch.branchId,
                  onTap: () => _select(context, branch),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BranchCard extends StatelessWidget {
  const _BranchCard({
    required this.branch,
    required this.selected,
    required this.onTap,
  });

  final TeacherBranch branch;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: selected ? 4 : 2,
      shadowColor: AppColors.navy.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.navy : AppColors.border,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
            child: Column(
              children: [
                SchoolLogo(
                  name: branch.title,
                  logoUrl: branch.logoUrl,
                  size: 120,
                  lightBackground: true,
                ),
                const SizedBox(height: 16),
                Text(
                  branch.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? AppColors.navy : AppColors.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
