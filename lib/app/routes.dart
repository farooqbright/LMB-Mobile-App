import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../models/auth_session.dart';
import '../parent/screens/parent_attendance_view.dart';
import '../parent/screens/parent_daily_diary_view.dart';
import '../parent/screens/parent_dashboard_view.dart';
import '../parent/screens/parent_placeholder_view.dart';
import '../parent/screens/parent_student_select_view.dart';
import '../parent/screens/parent_timetable_view.dart';
import '../services/session_store.dart';
import '../views/attendance/teacher_attendance_view.dart';
import '../views/auth/change_password_view.dart';
import '../views/auth/login_view.dart';
import '../views/branches/teacher_branch_select_view.dart';
import '../views/class_attendance/teacher_class_attendance_view.dart';
import '../views/dashboards/teacher_dashboard_view.dart';
import '../views/diary/teacher_daily_diary_view.dart';
import '../views/exams/teacher_exams_view.dart';
import '../views/profile/teacher_profile_view.dart';
import '../views/splash/splash_view.dart';
import '../views/tests_hw/teacher_tests_hw_view.dart';
import '../views/timetable/teacher_timetable_view.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String teacherDashboard = '/teacher-dashboard';
  static const String parentDashboard = '/parent-dashboard';
  static const String parentStudentSelect = '/parent-students';
  static const String parentAttendance = '/parent-attendance';
  static const String parentDailyDiary = '/parent-daily-diary';
  static const String parentFeeVouchers = '/parent-fee-vouchers';
  static const String parentTimetable = '/parent-timetable';
  static const String parentResults = '/parent-results';
  static const String parentDatesheet = '/parent-datesheet';
  static const String teacherProfile = '/teacher-profile';
  static const String teacherTimetable = '/teacher-timetable';
  static const String teacherAttendance = '/teacher-attendance';
  static const String teacherDailyDiary = '/teacher-daily-diary';
  static const String teacherClassAttendance = '/teacher-class-attendance';
  static const String teacherExams = '/teacher-exams';
  static const String teacherTestsHw = '/teacher-tests-hw';
  static const String teacherBranchSelect = '/teacher-branches';
  static const String changePassword = '/change-password';

  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => const SplashView(),
        login: (_) => const LoginView(),
      };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name == teacherBranchSelect) {
      final session = _sessionOf(settings);
      if (session == null || !session.isTeacher) {
        return MaterialPageRoute(builder: (_) => const LoginView());
      }
      return MaterialPageRoute(
        builder: (_) => TeacherBranchSelectView(session: session),
        settings: settings,
      );
    }

    if (settings.name == teacherDashboard) {
      final session = _sessionOf(settings);
      if (session == null || !session.isTeacher) {
        return MaterialPageRoute(builder: (_) => const LoginView());
      }
      return MaterialPageRoute(
        builder: (_) => TeacherDashboardView(session: session),
        settings: settings,
      );
    }

    if (settings.name == parentDashboard) {
      return _parentRoute(
        settings,
        (session) => ParentDashboardView(session: session),
      );
    }

    if (settings.name == parentStudentSelect) {
      return _parentRoute(
        settings,
        (session) => ParentStudentSelectView(session: session),
      );
    }

    if (settings.name == parentAttendance) {
      return _parentRoute(
        settings,
        (session) => ParentAttendanceView(session: session),
      );
    }

    if (settings.name == parentDailyDiary) {
      return _parentRoute(
        settings,
        (session) => ParentDailyDiaryView(session: session),
      );
    }

    if (settings.name == parentFeeVouchers) {
      return _parentRoute(
        settings,
        (_) => const ParentPlaceholderView(title: AppStrings.feeVouchers),
      );
    }

    if (settings.name == parentTimetable) {
      return _parentRoute(
        settings,
        (session) => ParentTimetableView(session: session),
      );
    }

    if (settings.name == parentResults) {
      return _parentRoute(
        settings,
        (_) => const ParentPlaceholderView(title: AppStrings.results),
      );
    }

    if (settings.name == parentDatesheet) {
      return _parentRoute(
        settings,
        (_) => const ParentPlaceholderView(title: AppStrings.datesheet),
      );
    }

    if (settings.name == teacherProfile) {
      final session = _sessionOf(settings);
      if (session == null || !session.isTeacher) {
        return MaterialPageRoute(builder: (_) => const LoginView());
      }
      return MaterialPageRoute(
        builder: (_) => TeacherProfileView(session: session),
        settings: settings,
      );
    }

    if (settings.name == teacherAttendance) {
      final session = _sessionOf(settings);
      if (session == null || !session.isTeacher) {
        return MaterialPageRoute(builder: (_) => const LoginView());
      }
      return MaterialPageRoute(
        builder: (_) => TeacherAttendanceView(session: session),
        settings: settings,
      );
    }

    if (settings.name == teacherTimetable) {
      final session = _sessionOf(settings);
      if (session == null || !session.isTeacher) {
        return MaterialPageRoute(builder: (_) => const LoginView());
      }
      return MaterialPageRoute(
        builder: (_) => TeacherTimetableView(session: session),
        settings: settings,
      );
    }

    if (settings.name == teacherDailyDiary) {
      final session = _sessionOf(settings);
      if (session == null || !session.isTeacher) {
        return MaterialPageRoute(builder: (_) => const LoginView());
      }
      return MaterialPageRoute(
        builder: (_) => TeacherDailyDiaryView(session: session),
        settings: settings,
      );
    }

    if (settings.name == teacherClassAttendance) {
      final session = _sessionOf(settings);
      if (session == null || !session.isTeacher) {
        return MaterialPageRoute(builder: (_) => const LoginView());
      }
      return MaterialPageRoute(
        builder: (_) => TeacherClassAttendanceView(session: session),
        settings: settings,
      );
    }

    if (settings.name == teacherExams) {
      final session = _sessionOf(settings);
      if (session == null || !session.isTeacher) {
        return MaterialPageRoute(builder: (_) => const LoginView());
      }
      return MaterialPageRoute(
        builder: (_) => TeacherExamsView(session: session),
        settings: settings,
      );
    }

    if (settings.name == teacherTestsHw) {
      final session = _sessionOf(settings);
      if (session == null || !session.isTeacher) {
        return MaterialPageRoute(builder: (_) => const LoginView());
      }
      return MaterialPageRoute(
        builder: (_) => TeacherTestsHwView(session: session),
        settings: settings,
      );
    }

    if (settings.name == changePassword) {
      final session = _sessionOf(settings);
      if (session == null) {
        return MaterialPageRoute(builder: (_) => const LoginView());
      }
      return MaterialPageRoute(
        builder: (_) => ChangePasswordView(session: session),
        settings: settings,
      );
    }

    return null;
  }

  static String dashboardFor(AuthSession session) {
    if (session.isParent) {
      if (session.needsStudentSelection) return parentStudentSelect;
      return parentDashboard;
    }
    if (session.needsBranchSelection) return teacherBranchSelect;
    return teacherDashboard;
  }

  static Route<dynamic> _parentRoute(
    RouteSettings settings,
    Widget Function(AuthSession session) builder,
  ) {
    final session = _sessionOf(settings);
    if (session == null || !session.isParent) {
      return MaterialPageRoute(builder: (_) => const LoginView());
    }
    return MaterialPageRoute(
      builder: (_) => builder(session),
      settings: settings,
    );
  }

  static AuthSession? _sessionOf(RouteSettings settings) {
    final arguments = settings.arguments;
    if (arguments is AuthSession) return arguments;
    return SessionStore.instance.current;
  }
}
