import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../models/auth_session.dart';
import 'dashboard_shell.dart';

class TeacherDashboardView extends StatelessWidget {
  const TeacherDashboardView({super.key, required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    final profile = session.teacherProfile;

    return DashboardShell(
      session: session,
      roleLabel: AppStrings.teacherRole,
      subtitle: AppStrings.teacherDashboardSubtitle,
      details: [
        DashboardDetail(
          label: 'Teacher',
          value: profile?.fullName?.trim().isNotEmpty == true
              ? profile!.fullName!
              : session.welcomeName,
        ),
        DashboardDetail(
          label: 'Employee no.',
          value: profile?.employeeNumber?.trim().isNotEmpty == true
              ? profile!.employeeNumber!
              : '—',
        ),
        DashboardDetail(
          label: 'Phone',
          value: profile?.phone?.trim().isNotEmpty == true ? profile!.phone! : '—',
        ),
        DashboardDetail(
          label: 'Email',
          value: session.user.email?.trim().isNotEmpty == true
              ? session.user.email!
              : '—',
        ),
        DashboardDetail(
          label: 'School',
          value: session.schoolName,
        ),
      ],
      actions: const [
        DashboardAction(
          icon: Icons.calendar_month_outlined,
          label: 'My Timetable',
          tint: Color(0xFFC2410C),
        ),
        DashboardAction(
          icon: Icons.how_to_reg_outlined,
          label: 'Class Attendance',
          tint: Color(0xFF047857),
        ),
        DashboardAction(
          icon: Icons.menu_book_outlined,
          label: 'Daily Diary',
          tint: Color(0xFF1D4ED8),
        ),
        DashboardAction(
          icon: Icons.edit_note_outlined,
          label: 'Tests & HW',
          tint: Color(0xFFB45309),
        ),
        DashboardAction(
          icon: Icons.assignment_outlined,
          label: 'Exams',
          tint: Color(0xFF4F46E5),
        ),
        DashboardAction(
          icon: Icons.badge_outlined,
          label: 'Student Info',
          tint: Color(0xFF0369A1),
        ),
      ],
    );
  }
}
