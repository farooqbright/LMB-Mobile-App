import 'package:flutter/material.dart';

import '../models/auth_session.dart';
import '../services/session_store.dart';
import '../views/auth/login_view.dart';
import '../views/dashboards/parent_dashboard_view.dart';
import '../views/dashboards/teacher_dashboard_view.dart';
import '../views/splash/splash_view.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String teacherDashboard = '/teacher-dashboard';
  static const String parentDashboard = '/parent-dashboard';

  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => const SplashView(),
        login: (_) => const LoginView(),
      };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
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
      final session = _sessionOf(settings);
      if (session == null || !session.isParent) {
        return MaterialPageRoute(builder: (_) => const LoginView());
      }
      return MaterialPageRoute(
        builder: (_) => ParentDashboardView(session: session),
        settings: settings,
      );
    }

    return null;
  }

  static String dashboardFor(AuthSession session) {
    return session.isTeacher ? teacherDashboard : parentDashboard;
  }

  static AuthSession? _sessionOf(RouteSettings settings) {
    final arguments = settings.arguments;
    if (arguments is AuthSession) return arguments;
    return SessionStore.instance.current;
  }
}
