import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../models/auth_session.dart';
import 'dashboard_shell.dart';

class TeacherDashboardView extends StatelessWidget {
  const TeacherDashboardView({super.key, required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      session: session,
      actions: const [
        DashboardAction(
          icon: Icons.calendar_month_rounded,
          label: AppStrings.myTimetable,
          route: AppRoutes.teacherTimetable,
        ),
        DashboardAction(
          icon: Icons.event_available_rounded,
          label: AppStrings.myAttendance,
          route: AppRoutes.teacherAttendance,
        ),
        DashboardAction(
          icon: Icons.how_to_reg_rounded,
          label: AppStrings.classAttendance,
          route: AppRoutes.teacherClassAttendance,
        ),
        DashboardAction(
          icon: Icons.menu_book_rounded,
          label: AppStrings.dailyDiary,
          route: AppRoutes.teacherDailyDiary,
        ),
        DashboardAction(
          icon: Icons.edit_note_rounded,
          label: AppStrings.testsAndHw,
          route: AppRoutes.teacherTestsHw,
        ),
        DashboardAction(
          icon: Icons.quiz_rounded,
          label: AppStrings.exams,
          route: AppRoutes.teacherExams,
        ),
        DashboardAction(
          icon: Icons.groups_rounded,
          label: 'Student Info',
        ),
      ],
    );
  }
}
