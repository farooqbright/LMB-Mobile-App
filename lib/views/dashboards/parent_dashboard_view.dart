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
    final child = session.selectedStudent;

    return DashboardShell(
      session: session,
      details: [
        DashboardDetail(
          label: 'Parent',
          value: profile?.fullName?.trim().isNotEmpty == true
              ? profile!.fullName!
              : session.welcomeName,
        ),
        if (child != null) ...[
          DashboardDetail(label: 'Student', value: child.title),
          if (child.classLabel.isNotEmpty)
            DashboardDetail(label: 'Class', value: child.classLabel),
          if ((child.rollNumber ?? '').trim().isNotEmpty)
            DashboardDetail(label: 'Roll no.', value: child.rollNumber!.trim()),
          if ((child.branchName ?? '').trim().isNotEmpty)
            DashboardDetail(label: 'Branch', value: child.branchName!.trim()),
        ] else
          const DashboardDetail(
            label: 'Student',
            value: AppStrings.noChildren,
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
          label: AppStrings.myChildren,
          route: AppRoutes.parentStudentSelect,
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
