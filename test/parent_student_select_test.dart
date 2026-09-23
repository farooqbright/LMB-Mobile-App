import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lmssystem/app/routes.dart';
import 'package:lmssystem/core/constants/app_strings.dart';
import 'package:lmssystem/models/auth_session.dart';
import 'package:lmssystem/parent/screens/parent_dashboard_view.dart';
import 'package:lmssystem/parent/screens/parent_student_select_view.dart';
import 'package:lmssystem/services/auth_service.dart';
import 'package:lmssystem/services/session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _parentPayload({
  required List<Map<String, dynamic>> children,
  int? selectedStudentId,
}) {
  return {
    'token': 'parent.token',
    'token_type': 'Bearer',
    'type': 'parent',
    'school': {'id': '1', 'name': 'SLS', 'domain': 'sls.localhost'},
    'user': {
      'id': 9,
      'name': 'Ali',
      'last_name': 'Parent',
      'username': '34101-0111110-6',
      'roles': ['Parent'],
    },
    'profile': {
      'type': 'parent',
      'guardian_id': 4,
      'full_name': 'Ali Parent',
      'cnic': '34101-0111110-6',
      'phone': '0300-1111111',
      'children': children,
    },
    if (selectedStudentId != null) 'selected_student_id': selectedStudentId,
  };
}

AuthSession _multiChildSession() {
  return AuthSession.fromJson(
    _parentPayload(
      children: [
        {
          'student_id': 11,
          'full_name': 'Ahmed Ali',
          'roll_number': '05',
          'class_name': 'Class 5',
          'section_name': 'A',
          'branch_name': 'Main Campus',
        },
        {
          'student_id': 12,
          'full_name': 'Sara Ali',
          'roll_number': '08',
          'class_name': 'Class 3',
          'section_name': 'B',
          'branch_name': 'Main Campus',
        },
      ],
    ),
  );
}

class _FakeAuthService extends AuthService {
  _FakeAuthService(this.refreshed);

  final AuthSession refreshed;
  var calls = 0;

  @override
  Future<AuthSession> refreshSession(AuthSession session) async {
    calls += 1;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return refreshed;
  }
}

void main() {
  setUp(() {
    SessionStore.instance.current = null;
    ParentStudentSelectView.debugAuthService = null;
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    ParentStudentSelectView.debugAuthService = null;
  });

  testWidgets('multi-child parent sees student list', (tester) async {
    final session = _multiChildSession();

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: ParentStudentSelectView(session: session),
      ),
    );

    expect(find.text(AppStrings.selectChild), findsOneWidget);
    expect(find.text('Ahmed Ali'), findsOneWidget);
    expect(find.text('Sara Ali'), findsOneWidget);
    expect(find.textContaining('Class 5 - A'), findsOneWidget);
    expect(find.text(AppStrings.activeStudent), findsNWidgets(2));
    expect(find.byType(ParentDashboardView), findsNothing);
  });

  testWidgets('inactive child is labelled like the parent web portal', (tester) async {
    final session = AuthSession.fromJson(
      _parentPayload(
        children: [
          {
            'student_id': 11,
            'full_name': 'Ahmed Ali',
            'class_name': 'Class 5',
            'section_name': 'A',
            'is_active': true,
            'status_label': 'Active',
          },
          {
            'student_id': 12,
            'full_name': 'Sara Ali',
            'class_name': 'Class 3',
            'section_name': 'B',
            'is_active': false,
            'enrollment_status': 'inactive',
            'is_enrollment_active': false,
            'status_label': 'Inactive',
          },
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: ParentStudentSelectView(session: session),
      ),
    );

    expect(find.text(AppStrings.activeStudent), findsOneWidget);
    expect(find.text(AppStrings.inactiveStudent), findsOneWidget);
    expect(find.text('Sara Ali'), findsOneWidget);
  });

  testWidgets('pulling down reloads children and shows a newly inactive student', (tester) async {
    final session = _multiChildSession();
    final fake = _FakeAuthService(
      AuthSession.fromJson(
        _parentPayload(
          children: [
            {
              'student_id': 11,
              'full_name': 'Ahmed Ali',
              'roll_number': '05',
              'class_name': 'Class 5',
              'section_name': 'A',
              'branch_name': 'Main Campus',
              'is_active': true,
              'status_label': 'Active',
            },
            {
              'student_id': 12,
              'full_name': 'Sara Ali',
              'roll_number': '08',
              'class_name': 'Class 3',
              'section_name': 'B',
              'branch_name': 'Main Campus',
              'is_active': false,
              'enrollment_status': 'inactive',
              'is_enrollment_active': false,
              'status_label': 'Inactive',
            },
          ],
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: ParentStudentSelectView(session: session, authService: fake),
      ),
    );
    expect(find.text(AppStrings.inactiveStudent), findsNothing);

    await tester.fling(find.byType(ListView), const Offset(0, 400), 1200);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('pull-refresh-loading')), findsOneWidget);
    await tester.pumpAndSettle();

    expect(fake.calls, 1);
    expect(find.text(AppStrings.inactiveStudent), findsOneWidget);
    expect(find.text(AppStrings.activeStudent), findsOneWidget);
  });

  testWidgets('choosing a child opens the parent dashboard', (tester) async {
    final session = _multiChildSession();

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: ParentStudentSelectView(session: session),
      ),
    );

    await tester.tap(find.text('Ahmed Ali'));
    await tester.pumpAndSettle();

    expect(find.byType(ParentDashboardView), findsOneWidget);
    expect(find.text('Ahmed Ali'), findsWidgets);
    expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Class 5 - A'), findsOneWidget);
    Navigator.of(tester.element(find.byType(Drawer))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(ParentStudentSelectView), findsOneWidget);
    expect(find.text(AppStrings.selectChild), findsOneWidget);
    expect(find.text('Ahmed Ali'), findsOneWidget);
    expect(find.text('Sara Ali'), findsOneWidget);
  });
}
