import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lmssystem/app/routes.dart';
import 'package:lmssystem/core/constants/app_strings.dart';
import 'package:lmssystem/core/network/api_client.dart';
import 'package:lmssystem/models/auth_session.dart';
import 'package:lmssystem/services/auth_service.dart';
import 'package:lmssystem/views/auth/change_password_view.dart';
import 'package:lmssystem/views/dashboards/teacher_dashboard_view.dart';

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

Finder _drawerScrollable() {
  return find.descendant(
    of: find.byType(Drawer),
    matching: find.byType(Scrollable),
  );
}

void main() {
  test('posts current and new password with school domain', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode({
          'status': 'success',
          'message': 'Password updated.',
          'data': null,
        }),
        200,
      );
    });

    await AuthService(client: ApiClient(httpClient: client)).changePassword(
      session: _teacherSession(),
      currentPassword: 'oldpass1',
      password: 'newpass12',
      passwordConfirmation: 'newpass12',
    );

    expect(captured.method, 'POST');
    expect(captured.url.path, contains('/mobile/auth/password'));
    expect(captured.headers['Authorization'], 'Bearer teacher.token');
    expect(jsonDecode(captured.body), {
      'domain': 'sls.localhost',
      'current_password': 'oldpass1',
      'password': 'newpass12',
      'password_confirmation': 'newpass12',
    });
  });

  testWidgets('drawer Change Password opens the form', (tester) async {
    final session = _teacherSession();
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: TeacherDashboardView(session: session),
      ),
    );

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(AppStrings.changePassword),
      80,
      scrollable: _drawerScrollable(),
    );
    await tester.ensureVisible(find.text(AppStrings.changePassword));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.changePassword));
    await tester.pumpAndSettle();

    expect(find.byType(ChangePasswordView), findsOneWidget);
    expect(find.text(AppStrings.currentPasswordLabel), findsOneWidget);
    expect(find.text(AppStrings.newPasswordLabel), findsOneWidget);
    expect(find.text(AppStrings.confirmPasswordLabel), findsOneWidget);
    expect(find.text(AppStrings.updatePassword), findsOneWidget);
  });

  testWidgets('change password validates empty fields', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangePasswordView(session: _teacherSession()),
      ),
    );

    await tester.tap(find.text(AppStrings.updatePassword));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.currentPasswordRequired), findsOneWidget);
    expect(find.text(AppStrings.newPasswordRequired), findsOneWidget);
    expect(find.text(AppStrings.confirmPasswordRequired), findsOneWidget);
  });

  testWidgets('change password submits and pops on success', (tester) async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'status': 'success',
          'message': 'Password updated.',
          'data': null,
        }),
        200,
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChangePasswordView(
                        session: _teacherSession(),
                        authService: AuthService(
                          client: ApiClient(httpClient: client),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'oldpass1');
    await tester.enterText(fields.at(1), 'newpass12');
    await tester.enterText(fields.at(2), 'newpass12');
    await tester.tap(find.text(AppStrings.updatePassword));
    await tester.pumpAndSettle();

    expect(find.byType(ChangePasswordView), findsNothing);
    expect(find.text(AppStrings.passwordUpdated), findsOneWidget);
  });
}
