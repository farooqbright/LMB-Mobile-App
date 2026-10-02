import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../services/notification_router.dart';
import '../services/push_notification_service.dart';
import 'routes.dart';

class LmsApp extends StatefulWidget {
  const LmsApp({super.key});

  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  State<LmsApp> createState() => _LmsAppState();
}

class _LmsAppState extends State<LmsApp> {
  @override
  void initState() {
    super.initState();
    NotificationRouter.instance.navigatorKey = LmsApp.navigatorKey;
    PushNotificationService.instance.bindTapHandler();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      navigatorKey: LmsApp.navigatorKey,
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
