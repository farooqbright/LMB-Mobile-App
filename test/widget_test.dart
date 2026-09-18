import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lmssystem/app/app.dart';
import 'package:lmssystem/models/auth_session.dart';
import 'package:lmssystem/services/connectivity_service.dart';
import 'package:lmssystem/services/session_store.dart';
import 'package:lmssystem/views/auth/login_view.dart';
import 'package:lmssystem/views/dashboards/teacher_dashboard_view.dart';
import 'package:lmssystem/views/splash/splash_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

AuthSession _teacherSession() {
  return AuthSession.fromJson({
    'token': 'teacher.token',
    'token_type': 'Bearer',
    'type': 'teacher',
    'school': {'id': '1', 'name': 'SLS', 'domain': 'sls.localhost'},
    'user': {
      'id': 3,
      'name': 'Sara',
      'last_name': 'Khan',
      'email': 'teacher@example.com',
      'username': 'teacher@example.com',
      'roles': ['Teacher'],
    },
    'profile': {
      'type': 'teacher',
      'teacher_id': 2,
      'branch_id': 1,
      'branch_name': 'Main Campus',
      'full_name': 'Sara Khan',
    },
  });
}

void main() {
  setUp(() {
    SessionStore.instance.current = null;
    ConnectivityService.instance.debugSetOnline(true);
    SharedPreferences.setMockInitialValues({});
  });
  testWidgets('splash loads then skip opens login', (WidgetTester tester) async {
    await tester.pumpWidget(const LmsApp());
    await tester.pump();
    await tester.pump();

    expect(find.byType(SplashView), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    expect(find.text('Skip'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginView), findsOneWidget);
    expect(find.text('School LMS'), findsWidgets);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Parent Login'), findsNothing);
    expect(find.text('SubDomain'), findsOneWidget);
    expect(find.text('Subdomain'), findsOneWidget);
    expect(find.text('Domain'), findsOneWidget);
  });

  testWidgets('saved teacher session opens dashboard after restart', (tester) async {
    final session = _teacherSession();
    SharedPreferences.setMockInitialValues({
      'auth_session': jsonEncode(session.toJson()),
    });

    await tester.pumpWidget(const LmsApp());
    await tester.pump();
    await tester.pump();

    expect(find.byType(LoginView), findsNothing);
    expect(find.byType(TeacherDashboardView), findsOneWidget);
  });

  testWidgets('login validates empty credentials and host type', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginView()));

    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('SubDomain is required'), findsOneWidget);
    expect(find.text('Username is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect(find.text('Parent Login'), findsNothing);
  });

  testWidgets('subdomain radio shows SubDomain field', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginView()));

    expect(find.text('SubDomain'), findsOneWidget);

    await tester.tap(find.text('Domain'));
    await tester.pump();

    expect(find.text('SubDomain'), findsNothing);
    expect(find.text('Domain'), findsNWidgets(2));
    expect(find.text('Enter domain, e.g. sls.198.211.105.64.nip.io'), findsOneWidget);
  });

  testWidgets('offline banner blocks the app until internet returns', (tester) async {
    ConnectivityService.instance.debugSetOnline(false);

    await tester.pumpWidget(const LmsApp());
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    expect(find.text('No internet connection'), findsOneWidget);
    expect(find.byType(SplashView), findsOneWidget);

    await tester.tap(find.text('Skip'), warnIfMissed: false);
    await tester.pump();
    expect(find.byType(LoginView), findsNothing);

    ConnectivityService.instance.debugSetOnline(true);
    await tester.pump();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('No internet connection'), findsNothing);
    expect(find.byType(LoginView), findsOneWidget);
  });
}
