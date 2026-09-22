import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lmssystem/app/routes.dart';
import 'package:lmssystem/core/constants/app_strings.dart';
import 'package:lmssystem/core/network/api_exception.dart';
import 'package:lmssystem/models/auth_session.dart';
import 'package:lmssystem/models/teacher_attendance.dart';
import 'package:lmssystem/models/teacher_timetable.dart';
import 'package:lmssystem/services/teacher_attendance_service.dart';
import 'package:lmssystem/services/teacher_timetable_service.dart';
import 'package:lmssystem/views/attendance/teacher_attendance_view.dart';
import 'package:lmssystem/views/dashboards/teacher_dashboard_view.dart';
import 'package:lmssystem/views/timetable/teacher_timetable_view.dart';

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

class _FakeAttendanceService extends TeacherAttendanceService {
  _FakeAttendanceService(this.data, {this.error});

  final TeacherAttendanceData data;
  final Object? error;
  var fetches = 0;

  @override
  Future<TeacherAttendanceData> fetch(
    AuthSession session, {
    TeacherAttendanceQuery query = const TeacherAttendanceQuery(),
  }) async {
    fetches += 1;
    if (error != null) {
      throw error!;
    }
    return data;
  }

  @override
  Future<BranchGeoFence> fetchLocation(AuthSession session) async {
    return const BranchGeoFence();
  }
}

class _FakeTimetableService extends TeacherTimetableService {
  _FakeTimetableService(this.data, {this.error});

  final TeacherTimetableData data;
  final Object? error;

  @override
  Future<TeacherTimetableData> fetch(AuthSession session) async {
    if (error != null) throw error!;
    return data;
  }
}

TeacherTimetableData _mondayTimetable() {
  return TeacherTimetableData.fromJson({
    'teacher': {'full_name': 'Sara Khan'},
    'branch': {'branch_id': 1, 'branch_name': 'Main Campus'},
    'schedules': [
      {
        'timetable_id': 3,
        'name': '6th To 10th',
        'working_days': [
          {'day': 1, 'label': 'Monday'},
        ],
        'periods': [
          {
            'id': 7,
            'name': 'Period 1',
            'start_time': '07:45',
            'end_time': '08:30',
          },
          {
            'id': 8,
            'name': 'Period 2',
            'start_time': '08:30',
            'end_time': '09:15',
          },
        ],
        'slots': const [],
        'grid': [
          {
            'period_id': 7,
            'period_name': 'Period 1',
            'start_time': '07:45',
            'end_time': '08:30',
            'days': [
              {
                'day': 1,
                'label': 'Monday',
                'lessons': [
                  {
                    'class_name': 'GRADE PRE-9th',
                    'section_name': 'ARTS',
                    'subject_name': 'Maths',
                  },
                ],
              },
            ],
          },
          {
            'period_id': 8,
            'period_name': 'Period 2',
            'start_time': '08:30',
            'end_time': '09:15',
            'days': [
              {
                'day': 1,
                'label': 'Monday',
                'lessons': [
                  {
                    'class_name': 'GRADE PRE-9th',
                    'section_name': 'ARTS',
                    'subject_name': 'English',
                  },
                ],
              },
            ],
          },
        ],
      },
    ],
  });
}

TeacherAttendanceData _presentToday() {
  return TeacherAttendanceData.fromJson({
    'teacher': {'full_name': 'Sara Khan'},
    'summary': {
      'today': {
        'status': 'present',
        'status_label': 'Present',
        'in_time_label': '07:12 AM',
        'out_time_label': '01:15 PM',
      },
      'month': {
        'total': 11,
        'present': 8,
        'absent': 1,
        'late': 2,
        'leave': 0,
        'short_leave': 0,
      },
    },
    'records': const [],
  });
}

void main() {
  testWidgets('teacher dashboard loads today attendance status', (tester) async {
    final fake = _FakeAttendanceService(_presentToday());

    await tester.pumpWidget(
      MaterialApp(
        home: TeacherDashboardView(
          session: _teacherSession(),
          attendanceService: fake,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(fake.fetches, 1);
    expect(find.text(AppStrings.todaysAttendance), findsOneWidget);
    expect(find.text('Present'), findsWidgets);
    expect(find.text('07:12 AM'), findsOneWidget);
    expect(find.text('01:15 PM'), findsOneWidget);
    expect(find.text(AppStrings.thisMonth), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('teacher dashboard shows not marked when today has no record', (tester) async {
    final fake = _FakeAttendanceService(
      TeacherAttendanceData.fromJson({
        'summary': {
          'today': null,
          'month': {'total': 0, 'present': 0, 'absent': 0, 'late': 0, 'leave': 0},
        },
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TeacherDashboardView(
          session: _teacherSession(),
          attendanceService: fake,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.todaysAttendance), findsOneWidget);
    expect(find.text(AppStrings.notMarked), findsOneWidget);
  });

  testWidgets('teacher dashboard retries attendance after an error', (tester) async {
    final fake = _FakeAttendanceService(
      const TeacherAttendanceData(),
      error: const ApiException('Unable to load your attendance.'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TeacherDashboardView(
          session: _teacherSession(),
          attendanceService: fake,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to load your attendance.'), findsOneWidget);
    expect(find.text(AppStrings.retry), findsOneWidget);
  });

  testWidgets('tapping dashboard attendance status opens my attendance', (tester) async {
    final session = _teacherSession();
    final fake = _FakeAttendanceService(_presentToday());

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.teacherAttendance) {
            return MaterialPageRoute(
              builder: (_) => TeacherAttendanceView(
                session: session,
                service: fake,
              ),
              settings: settings,
            );
          }
          return AppRoutes.onGenerateRoute(settings);
        },
        home: TeacherDashboardView(
          session: session,
          attendanceService: fake,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.todaysAttendance));
    await tester.pumpAndSettle();

    expect(find.byType(TeacherAttendanceView), findsOneWidget);
  });

  testWidgets('teacher dashboard shows the upcoming period', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TeacherDashboardView(
          session: _teacherSession(),
          attendanceService: _FakeAttendanceService(_presentToday()),
          timetableService: _FakeTimetableService(_mondayTimetable()),
          clock: () => DateTime(2026, 9, 14, 7, 0),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.upcomingPeriod), findsOneWidget);
    expect(find.text(AppStrings.periodUpNext), findsOneWidget);
    expect(find.text('Period 1'), findsOneWidget);
    expect(find.text('07:45 – 08:30'), findsOneWidget);
    expect(find.text('Maths'), findsOneWidget);
    expect(find.text('GRADE PRE-9th · ARTS'), findsOneWidget);
  });

  testWidgets('teacher dashboard shows the current period as now', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TeacherDashboardView(
          session: _teacherSession(),
          attendanceService: _FakeAttendanceService(_presentToday()),
          timetableService: _FakeTimetableService(_mondayTimetable()),
          clock: () => DateTime(2026, 9, 14, 8, 0),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.periodNow), findsOneWidget);
    expect(find.text('Period 1'), findsOneWidget);
    expect(find.text('Maths'), findsOneWidget);
  });

  testWidgets('teacher dashboard shows empty upcoming period after the last class', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TeacherDashboardView(
          session: _teacherSession(),
          attendanceService: _FakeAttendanceService(_presentToday()),
          timetableService: _FakeTimetableService(_mondayTimetable()),
          clock: () => DateTime(2026, 9, 14, 10, 0),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.upcomingPeriod), findsOneWidget);
    expect(find.text(AppStrings.noUpcomingPeriod), findsOneWidget);
  });

  testWidgets('tapping upcoming period opens the timetable', (tester) async {
    final session = _teacherSession();
    final timetable = _FakeTimetableService(_mondayTimetable());

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.teacherTimetable) {
            return MaterialPageRoute(
              builder: (_) => TeacherTimetableView(
                session: session,
                service: timetable,
                clock: () => DateTime(2026, 9, 14, 7, 0),
              ),
              settings: settings,
            );
          }
          return AppRoutes.onGenerateRoute(settings);
        },
        home: TeacherDashboardView(
          session: session,
          attendanceService: _FakeAttendanceService(_presentToday()),
          timetableService: timetable,
          clock: () => DateTime(2026, 9, 14, 7, 0),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.upcomingPeriod));
    await tester.pumpAndSettle();

    expect(find.byType(TeacherTimetableView), findsOneWidget);
  });

  testWidgets('teacher dashboard shows feature cards under the upcoming period', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TeacherDashboardView(
          session: _teacherSession(),
          attendanceService: _FakeAttendanceService(_presentToday()),
          timetableService: _FakeTimetableService(_mondayTimetable()),
          clock: () => DateTime(2026, 9, 14, 7, 0),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.upcomingPeriod), findsOneWidget);
    expect(find.text(AppStrings.myTimetable), findsOneWidget);
    expect(find.text(AppStrings.myAttendance), findsOneWidget);
    expect(find.text(AppStrings.classAttendance), findsOneWidget);
    expect(find.text(AppStrings.dailyDiary), findsOneWidget);
    expect(find.text(AppStrings.specialRemarks), findsOneWidget);
    expect(find.text(AppStrings.exams), findsOneWidget);
    expect(find.text(AppStrings.testsAndHw), findsOneWidget);
  });
}
