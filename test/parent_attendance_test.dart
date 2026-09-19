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
    if (query.status == 'absent') {
      return ParentAttendanceData(
        studentName: data.studentName,
        className: data.className,
        sectionName: data.sectionName,
        branchName: data.branchName,
        monthLabel: data.monthLabel,
        statuses: data.statuses,
        summary: data.summary,
        records: data.records.where((record) => record.status == 'absent').toList(),
        meta: data.meta,
      );
    }
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
    'statuses': [
      {'key': 'present', 'label': 'Present'},
      {'key': 'absent', 'label': 'Absent'},
      {'key': 'late', 'label': 'Late'},
      {'key': 'leave', 'label': 'Leave'},
    ],
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
    expect(data.statuses.map((item) => item.key), ['present', 'absent', 'late', 'leave']);
    expect(data.records, hasLength(2));
    expect(data.records.last.displayStatus, 'Absent');
  });

  test('defaults the filter range to the current month', () {
    final controller = ParentAttendanceController(
      session: _parentSession(),
      clock: () => DateTime(2026, 9, 17),
    );

    expect(isoAttendanceDate(controller.dateFrom), '2026-09-01');
    expect(isoAttendanceDate(controller.dateTo), '2026-09-30');
    expect(controller.hasActiveFilters, isFalse);
  });

  testWidgets('shows selected student attendance stats and filters', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ParentAttendanceView(
          session: _parentSession(),
          service: _FakeAttendanceService(_sampleData()),
          clock: () => DateTime(2026, 9, 18),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.attendance), findsOneWidget);
    expect(find.text('Ahmed Ali'), findsOneWidget);
    expect(find.text('Class 5 - A · Main Campus'), findsOneWidget);
    expect(find.text(AppStrings.attendanceToday), findsOneWidget);
    expect(find.text('Present'), findsWidgets);
    expect(find.text('8'), findsOneWidget);
    expect(find.text(AppStrings.allStatuses), findsOneWidget);
    expect(find.text(AppStrings.filter), findsOneWidget);
    expect(find.text(AppStrings.fromDate), findsOneWidget);
    expect(find.text(AppStrings.toDate), findsOneWidget);
    expect(find.text('01/09/2026'), findsOneWidget);
    expect(find.text('30/09/2026'), findsOneWidget);
    expect(find.text('18 Sep 2026'), findsOneWidget);
    expect(find.text('17 Sep 2026'), findsOneWidget);
  });

  testWidgets('applying a status filter reloads matching records', (tester) async {
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

    await tester.tap(find.byType(DropdownButton<String?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Absent').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.filter));
    await tester.pumpAndSettle();

    expect(fake.fetches, 2);
    expect(fake.lastQuery?.status, 'absent');
    expect(find.text('17 Sep 2026'), findsOneWidget);
    expect(find.text('18 Sep 2026'), findsNothing);
    expect(find.byTooltip(AppStrings.clearFilters), findsOneWidget);
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
}
