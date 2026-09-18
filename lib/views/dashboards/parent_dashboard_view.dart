import 'package:flutter/material.dart';

import '../../app/routes.dart';
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
        ),
        DashboardAction(
          icon: Icons.fact_check_outlined,
          label: 'Attendance',
        ),
        DashboardAction(
          icon: Icons.payments_outlined,
          label: 'Fees',
        ),
        DashboardAction(
          icon: Icons.menu_book_outlined,
          label: 'Daily Diary',
        ),
        DashboardAction(
          icon: Icons.assignment_outlined,
          label: 'Exams',
        ),
        DashboardAction(
          icon: Icons.notifications_none_rounded,
          label: 'Notices',
        ),
        DashboardAction(
          icon: Icons.lock_reset_rounded,
          label: AppStrings.changePassword,
          route: AppRoutes.changePassword,
        ),
      ],
    );
  }
}
