import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/auth_session.dart';
import 'dashboard_shell.dart';

class ParentDashboardView extends StatelessWidget {
  const ParentDashboardView({super.key, required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    final profile = session.parentProfile;

    return DashboardShell(
      session: session,
      roleLabel: AppStrings.parentRole,
      subtitle: AppStrings.parentDashboardSubtitle,
      details: [
        DashboardDetail(
          label: 'Parent',
          value: profile?.fullName?.trim().isNotEmpty == true
              ? profile!.fullName!
              : session.welcomeName,
        ),
        DashboardDetail(
          label: 'CNIC',
          value: profile?.cnic?.trim().isNotEmpty == true
              ? profile!.cnic!
              : (session.user.username ?? '—'),
        ),
        DashboardDetail(
          label: 'Phone',
          value: profile?.phone?.trim().isNotEmpty == true ? profile!.phone! : '—',
        ),
        DashboardDetail(
          label: 'School',
          value: session.schoolName,
        ),
      ],
      actions: const [
        DashboardAction(
          icon: Icons.family_restroom_rounded,
          label: 'My Children',
          tint: AppColors.navy,
        ),
        DashboardAction(
          icon: Icons.fact_check_outlined,
          label: 'Attendance',
          tint: Color(0xFF047857),
        ),
        DashboardAction(
          icon: Icons.payments_outlined,
          label: 'Fees',
          tint: Color(0xFFB45309),
        ),
        DashboardAction(
          icon: Icons.menu_book_outlined,
          label: 'Daily Diary',
          tint: Color(0xFF1D4ED8),
        ),
        DashboardAction(
          icon: Icons.assignment_outlined,
          label: 'Exams',
          tint: Color(0xFF4F46E5),
        ),
        DashboardAction(
          icon: Icons.notifications_none_rounded,
          label: 'Notices',
          tint: Color(0xFF0E7490),
        ),
      ],
    );
  }
}
