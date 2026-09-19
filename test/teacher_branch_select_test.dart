import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lmssystem/app/routes.dart';
import 'package:lmssystem/core/constants/app_strings.dart';
import 'package:lmssystem/models/auth_session.dart';
import 'package:lmssystem/services/session_store.dart';
import 'package:lmssystem/views/branches/teacher_branch_select_view.dart';
import 'package:lmssystem/views/dashboards/teacher_dashboard_view.dart';
import 'package:lmssystem/views/widgets/school_logo.dart';
import 'package:shared_preferences/shared_preferences.dart';

AuthSession _multiBranchSession() {
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
      'branch_name': 'Avicenna Campus',
      'full_name': 'Sara Khan',
      'branches': [
        {'branch_id': 1, 'branch_name': 'Avicenna Campus'},
        {'branch_id': 2, 'branch_name': 'Ibn Sina Campus'},
      ],
    },
  });
}

void main() {
  setUp(() {
    SessionStore.instance.current = null;
    SharedPreferences.setMockInitialValues({});
  });
  testWidgets('multi-branch teacher sees campus list with logos', (tester) async {
    final session = _multiBranchSession();

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: TeacherBranchSelectView(session: session),
      ),
    );

    expect(find.text(AppStrings.selectBranch), findsOneWidget);
    expect(find.text('Avicenna Campus'), findsOneWidget);
    expect(find.text('Ibn Sina Campus'), findsOneWidget);
    expect(find.byType(SchoolLogo), findsWidgets);
    expect(find.byType(TeacherDashboardView), findsNothing);
  });

  testWidgets('choosing a branch opens the teacher dashboard', (tester) async {
    final session = _multiBranchSession();

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: TeacherBranchSelectView(session: session),
      ),
    );

    await tester.tap(find.text('Avicenna Campus'));
    await tester.pumpAndSettle();

    expect(find.byType(TeacherDashboardView), findsOneWidget);
    expect(find.text('Welcome, Sara Khan'), findsNothing);
    expect(find.text('Avicenna Campus'), findsOneWidget);
    expect(find.text('My Timetable'), findsNothing);
    expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(find.text('Change branch'), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(TeacherBranchSelectView), findsOneWidget);
    expect(find.text(AppStrings.selectBranch), findsOneWidget);
    expect(find.text('Avicenna Campus'), findsOneWidget);
  });
}
