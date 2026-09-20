import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lmssystem/core/constants/app_strings.dart';
import 'package:lmssystem/core/network/api_exception.dart';
import 'package:lmssystem/models/auth_session.dart';
import 'package:lmssystem/models/teacher_attendance.dart';
import 'package:lmssystem/parent/controllers/parent_attendance_controller.dart';
import 'package:lmssystem/parent/models/parent_attendance.dart';
import 'package:lmssystem/parent/screens/parent_attendance_view.dart';
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
      'children': [
        {
          'student_id': 11,
          'full_name': 'Ahmed Ali',
          'class_name': 'Class 5',
          'section_name': 'A',
          'branch_name': 'Main Campus',
        },
      ],
    },
    'selected_student_id': 11,
  });
}

class _FakeAttendanceService extends ParentAttendanceService {
  _FakeAttendanceService(this.data, {this.error});

  final ParentAttendanceData data;
  final Object? error;
  ParentAttendanceQuery? lastQuery;
  var fetches = 0;

  @override
  Future<ParentAttendanceData> fetch(
    AuthSession session, {
    ParentAttendanceQuery query = const ParentAttendanceQuery(),
  }) async {
    fetches += 1;
    lastQuery = query;
    if (error != null) throw error!;
    return data;
  }
}

ParentAttendanceData _sampleData() {
  return ParentAttendanceData.fromJson({
    'student': {
      'student_id': 11,
      'full_name': 'Ahmed Ali',
      'class_name': 'Class 5',
      'section_name': 'A',
      'branch_name': 'Main Campus',
    },
    'month_label': 'September 2026',
    'last_month_label': 'August 2026',
    'statuses': [
      {'key': 'present', 'label': 'Present'},
      {'key': 'absent', 'label': 'Absent'},
      {'key': 'late', 'label': 'Late'},
      {'key': 'leave', 'label': 'Leave'},
    ],
    'summary': {
      'today': {'status': 'present', 'status_label': 'Present'},
      'month': {'total': 10, 'present': 8, 'absent': 1, 'late': 1, 'leave': 0},
      'last_month': {'total': 12, 'present': 9, 'absent': 2, 'late': 1, 'leave': 0},
    },
    'last_30_days': [
      {
        'id': 1,
        'date': '2026-09-18',
        'date_label': '18 Sep 2026',
        'status': 'present',
        'status_label': 'Present',
      },
      {
        'id': 2,
        'date': '2026-09-17',
        'date_label': '17 Sep 2026',
        'status': 'absent',
        'status_label': 'Absent',
      },
    ],
    'records': [
      {
        'id': 1,
        'date': '2026-09-18',
        'date_label': '18 Sep 2026',
        'status': 'present',
        'status_label': 'Present',
      },
      {
        'id': 2,
        'date': '2026-09-17',
        'date_label': '17 Sep 2026',
        'status': 'absent',
        'status_label': 'Absent',
      },
    ],
  });
}

void main() {
  test('parses student attendance summary and statuses', () {
    final data = _sampleData();

    expect(data.studentName, 'Ahmed Ali');
    expect(data.classLabel, 'Class 5 - A');
    expect(data.summary.today?.status, 'present');
    expect(data.summary.month.present, 8);
    expect(data.summary.lastMonth.present, 9);
    expect(data.lastMonthLabel, 'August 2026');
    expect(data.lastThirtyDays, hasLength(2));
    expect(data.statuses.map((item) => item.key), ['present', 'absent', 'late', 'leave']);
    expect(data.records, hasLength(2));
    expect(data.records.last.displayStatus, 'Absent');
  });

  test('defaults the filter range to this month', () {
    final controller = ParentAttendanceController(
      session: _parentSession(),
      clock: () => DateTime(2026, 9, 17),
    );

    expect(controller.period, ParentAttendancePeriod.month);
    expect(isoAttendanceDate(controller.dateFrom), '2026-09-01');
    expect(isoAttendanceDate(controller.dateTo), '2026-09-30');
    expect(controller.rangeLabel, 'September 2026');
  });

  test('last week uses the previous Monday to Sunday', () async {
    final controller = ParentAttendanceController(
      session: _parentSession(),
      service: _FakeAttendanceService(_sampleData()),
      clock: () => DateTime(2026, 9, 18),
    );

    await controller.selectPeriod(ParentAttendancePeriod.lastWeek);

    expect(isoAttendanceDate(controller.dateFrom), '2026-09-07');
    expect(isoAttendanceDate(controller.dateTo), '2026-09-13');
    expect(controller.rangeLabel, 'Last week · 07 Sep 2026 — 13 Sep 2026');
  });

  test('last month uses the previous calendar month', () async {
    final controller = ParentAttendanceController(
      session: _parentSession(),
      service: _FakeAttendanceService(_sampleData()),
      clock: () => DateTime(2026, 9, 18),
    );

    await controller.selectPeriod(ParentAttendancePeriod.lastMonth);

    expect(isoAttendanceDate(controller.dateFrom), '2026-08-01');
    expect(isoAttendanceDate(controller.dateTo), '2026-08-31');
    expect(controller.rangeLabel, 'Last month · August 2026');
  });

  testWidgets('shows selected student attendance stats and filters', (tester) async {
    final fake = _FakeAttendanceService(_sampleData());

    await tester.pumpWidget(
      MaterialApp(
        home: ParentAttendanceView(
          session: _parentSession(),
          service: fake,
          clock: () => DateTime(2026, 9, 18),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(fake.lastQuery?.dateFrom, '2026-09-01');
    expect(fake.lastQuery?.dateTo, '2026-09-30');
    expect(find.text(AppStrings.attendance), findsOneWidget);
    expect(find.text('Ahmed Ali'), findsOneWidget);
    expect(find.text('Class 5 - A · Main Campus'), findsOneWidget);
    expect(find.text(AppStrings.todaysAttendance), findsOneWidget);
    expect(find.text('Present'), findsWidgets);
    expect(find.text(AppStrings.lastMonth), findsWidgets);
    expect(find.text('August 2026'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text(AppStrings.quickFilters), findsOneWidget);
    expect(find.text(AppStrings.thisMonth), findsOneWidget);
    expect(find.text(AppStrings.lastWeek), findsOneWidget);
    expect(find.text(AppStrings.betweenDates), findsOneWidget);
    expect(find.text(AppStrings.attendanceDetails), findsOneWidget);
    expect(find.text('September 2026'), findsOneWidget);
    expect(find.text(AppStrings.apply), findsNothing);
    expect(find.text(AppStrings.fromDate), findsNothing);
    expect(find.text('18 Sep 2026'), findsOneWidget);
    expect(find.text('17 Sep 2026'), findsOneWidget);
  });

  testWidgets('last week filter reloads that date range', (tester) async {
    final fake = _FakeAttendanceService(_sampleData());

    await tester.pumpWidget(
      MaterialApp(
        home: ParentAttendanceView(
          session: _parentSession(),
          service: fake,
          clock: () => DateTime(2026, 9, 18),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.lastWeek));
    await tester.pumpAndSettle();

    expect(fake.fetches, 2);
    expect(fake.lastQuery?.dateFrom, '2026-09-07');
    expect(fake.lastQuery?.dateTo, '2026-09-13');
    expect(find.text('Last week · 07 Sep 2026 — 13 Sep 2026'), findsOneWidget);
  });

  testWidgets('between dates shows a custom range to apply', (tester) async {
    final fake = _FakeAttendanceService(_sampleData());

    await tester.pumpWidget(
      MaterialApp(
        home: ParentAttendanceView(
          session: _parentSession(),
          service: fake,
          clock: () => DateTime(2026, 9, 18),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.betweenDates));
    await tester.pumpAndSettle();

    expect(fake.fetches, 1);
    expect(find.text(AppStrings.fromDate), findsOneWidget);
    expect(find.text(AppStrings.toDate), findsOneWidget);
    expect(find.text('01/09/2026'), findsOneWidget);
    expect(find.text('18/09/2026'), findsOneWidget);
    expect(find.text(AppStrings.apply), findsOneWidget);
    expect(find.text(AppStrings.reset), findsOneWidget);

    await tester.tap(find.text(AppStrings.apply));
    await tester.pumpAndSettle();

    expect(fake.fetches, 2);
    expect(fake.lastQuery?.dateFrom, '2026-09-01');
    expect(fake.lastQuery?.dateTo, '2026-09-18');
  });

  testWidgets('shows attendance error and retry', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ParentAttendanceView(
          session: _parentSession(),
          service: _FakeAttendanceService(
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

  testWidgets('shows load more when more attendance pages exist', (tester) async {
    final fake = _FakeAttendanceService(
      ParentAttendanceData.fromJson({
        'student': {
          'student_id': 11,
          'full_name': 'Ahmed Ali',
          'class_name': 'Class 5',
          'section_name': 'A',
          'branch_name': 'Main Campus',
        },
        'summary': {
          'today': {'status': 'present', 'status_label': 'Present'},
          'month': {'total': 1, 'present': 1, 'absent': 0, 'late': 0, 'leave': 0},
          'last_month': {'total': 0, 'present': 0, 'absent': 0, 'late': 0, 'leave': 0},
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
      }, metaJson: {
        'current_page': 1,
        'last_page': 2,
        'per_page': 25,
        'total': 2,
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ParentAttendanceView(
          session: _parentSession(),
          service: fake,
          clock: () => DateTime(2026, 9, 18),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.loadMore), findsOneWidget);
  });
}
