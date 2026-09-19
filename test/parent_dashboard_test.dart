import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lmssystem/app/routes.dart';
import 'package:lmssystem/core/constants/app_strings.dart';
import 'package:lmssystem/core/network/api_exception.dart';
import 'package:lmssystem/models/auth_session.dart';
import 'package:lmssystem/parent/models/parent_attendance.dart';
import 'package:lmssystem/parent/screens/parent_attendance_view.dart';
import 'package:lmssystem/parent/screens/parent_dashboard_view.dart';
import 'package:lmssystem/parent/screens/parent_placeholder_view.dart';
import 'package:lmssystem/parent/services/parent_attendance_service.dart';

AuthSession _parentSession() {
  return AuthSession.fromJson({
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
      'children': [
        {
          'student_id': 11,
          'full_name': 'Ahmed Ali',
          'roll_number': '05',
          'class_name': 'Class 5',
          'section_name': 'A',
          'branch_name': 'Main Campus',
        },
      ],
    },
  });
}

class _FakeAttendanceService extends ParentAttendanceService {
  _FakeAttendanceService(this.data, {this.error});

  final ParentAttendanceData data;
  final Object? error;

  @override
  Future<ParentAttendanceData> fetch(
    AuthSession session, {
    ParentAttendanceQuery query = const ParentAttendanceQuery(),
  }) async {
    if (error != null) throw error!;
    return data;
  }
}

ParentAttendanceData _presentToday() {
  return ParentAttendanceData.fromJson({
    'student': {
      'student_id': 11,
      'full_name': 'Ahmed Ali',
      'class_name': 'Class 5',
      'section_name': 'A',
    },
    'month_label': 'September 2026',
    'summary': {
      'today': {'status': 'present', 'status_label': 'Present'},
      'month': {'total': 10, 'present': 8, 'absent': 1, 'late': 1, 'leave': 0},
    },
    'records': [
      {
        'id': 1,
        'date': '2026-09-18',
        'date_label': '18 Sep 2026',
        'status': 'present',
        'status_label': 'Present',
      },
    ],
  });
}

void main() {
  testWidgets('parent dashboard shows student attendance status', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ParentDashboardView(
          session: _parentSession(),
          attendanceService: _FakeAttendanceService(_presentToday()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.todaysAttendance), findsOneWidget);
    expect(find.text('Present'), findsWidgets);
    expect(find.text(AppStrings.thisMonth), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
  });

  testWidgets('parent dashboard retries attendance after an error', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ParentDashboardView(
          session: _parentSession(),
          attendanceService: _FakeAttendanceService(
            const ParentAttendanceData(),
            error: const ApiException('Unable to load attendance.'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to load attendance.'), findsOneWidget);
    expect(find.text(AppStrings.retry), findsOneWidget);
  });

  testWidgets('tapping attendance status opens student attendance', (tester) async {
    final session = _parentSession();
    final fake = _FakeAttendanceService(_presentToday());

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.parentAttendance) {
            return MaterialPageRoute(
              builder: (_) => ParentAttendanceView(
                session: session,
                service: fake,
              ),
              settings: settings,
            );
          }
          return AppRoutes.onGenerateRoute(settings);
        },
        home: ParentDashboardView(
          session: session,
          attendanceService: fake,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.todaysAttendance));
    await tester.pumpAndSettle();

    expect(find.byType(ParentAttendanceView), findsOneWidget);
    expect(find.text('18 Sep 2026'), findsOneWidget);
  });

  testWidgets('drawer shows student identity and parent links', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: ParentDashboardView(
          session: _parentSession(),
          attendanceService: _FakeAttendanceService(_presentToday()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Ahmed Ali'), findsWidgets);
    expect(find.text('Class 5 - A'), findsOneWidget);
    expect(find.text(AppStrings.attendance), findsOneWidget);
    expect(find.text(AppStrings.dailyDiary), findsOneWidget);
    expect(find.text(AppStrings.feeVouchers), findsOneWidget);
    expect(find.text(AppStrings.timeTable), findsOneWidget);
    expect(find.text(AppStrings.results), findsOneWidget);
    expect(find.text(AppStrings.datesheet), findsOneWidget);
  });

  testWidgets('tapping Daily Diary opens the placeholder', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: ParentDashboardView(
          session: _parentSession(),
          attendanceService: _FakeAttendanceService(_presentToday()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.text(AppStrings.dailyDiary),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ParentPlaceholderView), findsOneWidget);
    expect(find.text(AppStrings.comingSoon), findsOneWidget);
  });
}
