import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lmssystem/app/app.dart';
import 'package:lmssystem/services/session_store.dart';
import 'package:lmssystem/views/auth/login_view.dart';
import 'package:lmssystem/views/splash/splash_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SessionStore.instance.current = null;
    SharedPreferences.setMockInitialValues({});
  });
  testWidgets('splash loads then skip opens login', (WidgetTester tester) async {
    await tester.pumpWidget(const LmsApp());
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
  });
}
