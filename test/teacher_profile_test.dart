import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lmssystem/app/routes.dart';
import 'package:lmssystem/models/auth_session.dart';
import 'package:lmssystem/views/dashboards/teacher_dashboard_view.dart';
import 'package:lmssystem/views/profile/teacher_profile_view.dart';
import 'package:lmssystem/views/widgets/school_logo.dart';
import 'package:lmssystem/views/widgets/user_avatar.dart';

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
      'avatar_url': null,
    },
    'profile': {
      'type': 'teacher',
      'teacher_id': 2,
      'branch_id': 1,
      'branch_name': 'Main Campus',
      'full_name': 'Sara Khan',
      'father_name': 'Ahmed Khan',
      'employee_number': 'T-01',
      'cnic': '35201-1234567-1',
      'phone': '0300-2222222',
      'email': 'teacher@example.com',
      'photo_url': null,
    },
  });
}

void main() {
  testWidgets('teacher dashboard hides welcome and profile details', (tester) async {
    final session = _teacherSession();

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: TeacherDashboardView(session: session),
      ),
    );

    expect(find.text('Welcome, Sara Khan'), findsNothing);
    expect(find.text('Teacher'), findsNothing);
    expect(
      find.text('Timetable, attendance, diary and tests for your school.'),
      findsNothing,
    );
    expect(find.text('My Timetable'), findsOneWidget);
    expect(find.text('My Attendance'), findsOneWidget);
    expect(find.text('Class Attendance'), findsOneWidget);
    expect(find.text('Daily Diary'), findsOneWidget);
    expect(find.text('Exams'), findsOneWidget);
    expect(find.text('Phase Tests'), findsOneWidget);
    expect(find.text('Employee no.'), findsNothing);
    expect(find.text('Father name'), findsNothing);
    expect(find.byType(UserAvatar), findsNothing);
    expect(find.byType(SchoolLogo), findsOneWidget);
    expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
    expect(find.byIcon(Icons.home_rounded), findsWidgets);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Sara Khan'), findsOneWidget);
    expect(find.text('Teacher'), findsOneWidget);
    expect(find.text('My Timetable'), findsNWidgets(2));
    expect(find.text('My Attendance'), findsNWidgets(2));
    expect(find.text('Class Attendance'), findsNWidgets(2));
    expect(find.text('Daily Diary'), findsNWidgets(2));
    expect(find.text('Special Remarks'), findsNWidgets(2));
    expect(find.text('Exams'), findsNWidgets(2));
    await tester.scrollUntilVisible(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.text('Phase Tests'),
      ),
      80,
      scrollable: find.descendant(
        of: find.byType(Drawer),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Phase Tests'), findsNWidgets(2));
    await tester.scrollUntilVisible(
      find.text('Student Info'),
      80,
      scrollable: find.descendant(
        of: find.byType(Drawer),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Student Info'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Change Password'),
      80,
      scrollable: find.descendant(
        of: find.byType(Drawer),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Change Password'), findsOneWidget);
    expect(find.byType(UserAvatar), findsOneWidget);
  });

  testWidgets('teacher bottom bar opens profile with details', (tester) async {
    final session = _teacherSession();

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: TeacherDashboardView(session: session),
      ),
    );

    await tester.tap(find.byIcon(Icons.person_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(TeacherProfileContent), findsOneWidget);
    expect(find.text('Sara Khan'), findsWidgets);
    expect(find.text('Father name'), findsOneWidget);
    expect(find.text('Ahmed Khan'), findsOneWidget);
    expect(find.text('T-01'), findsOneWidget);
    expect(find.text('Main Campus'), findsOneWidget);
  });
}
