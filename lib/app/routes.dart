import 'package:flutter/material.dart';

import '../views/auth/login_view.dart';
import '../views/splash/splash_view.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';

  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => const SplashView(),
        login: (_) => const LoginView(),
      };
}
