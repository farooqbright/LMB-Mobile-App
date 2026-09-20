import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lmssystem/core/constants/app_strings.dart';
import 'package:lmssystem/core/network/api_exception.dart';
import 'package:lmssystem/models/auth_session.dart';
import 'package:lmssystem/parent/controllers/parent_timetable_controller.dart';
import 'package:lmssystem/parent/models/parent_timetable.dart';
import 'package:lmssystem/parent/screens/parent_timetable_view.dart';
import 'package:lmssystem/parent/services/parent_timetable_service.dart';

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

class _FakeTimetableService extends ParentTimetableService {
  _FakeTimetableService(this.data, {this.error});

  final ParentTimetableData data;
  final Object? error;
  var fetches = 0;

  @override
  Future<ParentTimetableData> fetch(AuthSession session) async {
    fetches += 1;
    if (error != null) throw error!;
    return data;
  }
}

ParentTimetableData _sampleData() {
  return ParentTimetableData.fromJson({
    'student': {
      'student_id': 11,
      'full_name': 'Ahmed Ali',
      'class_name': 'Class 5',
      'section_name': 'A',
      'branch_name': 'Main Campus',
    },
    'has_enrollment': true,
    'schedule': {
      'timetable_id': 3,
      'name': 'Winter timetable',
      'label': 'Class 5 — A',
      'branch_id': 1,
      'branch_name': 'Main Campus',
      'session': {'id': 1, 'name': '2026-27'},
      'slot_count': 2,
      'working_days': [
        {'day': 1, 'label': 'Monday'},
        {'day': 2, 'label': 'Tuesday'},
      ],
      'periods': [
        {
          'id': 7,
          'name': 'Period 1',
          'start_time': '07:45',
          'end_time': '08:30',
          'sort_order': 1,
        },
      ],
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
                  'subject_name': 'Mathematics',
                  'teacher_name': 'Sir Ali',
                },
              ],
            },
            {'day': 2, 'label': 'Tuesday', 'lessons': []},
          ],
        },
      ],
    },
  });
}

void main() {
  test('parses student timetable slots and teacher names', () {
    final data = _sampleData();

    expect(data.studentName, 'Ahmed Ali');
    expect(data.classLabel, 'Class 5 - A');
    expect(data.hasEnrollment, isTrue);
    expect(data.schedule?.title, 'Class 5 — A');
    expect(data.schedule?.name, 'Winter timetable');
    expect(data.schedule?.slotCount, 2);

    final monday = data.schedule!.cellsForDay(1);
    expect(monday, hasLength(1));
    expect(monday.first.title, 'Period 1');
    expect(monday.first.lessons.first.title, 'Mathematics');
    expect(monday.first.lessons.first.subtitle, 'Sir Ali');

    final tuesday = data.schedule!.cellsForDay(2);
    expect(tuesday.first.isFree, isTrue);
  });

  test('defaults the selected day to today when it is a working day', () {
    final controller = ParentTimetableController(
      session: _parentSession(),
      service: _FakeTimetableService(_sampleData()),
      clock: () => DateTime(2026, 9, 14, 8),
    );

    expect(controller.currentDay, DateTime.monday);
  });

  testWidgets('shows selected student timetable for today', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ParentTimetableView(
          session: _parentSession(),
          service: _FakeTimetableService(_sampleData()),
          clock: () => DateTime(2026, 9, 14, 8),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.timeTable), findsOneWidget);
    expect(find.text('Ahmed Ali'), findsOneWidget);
    expect(find.text('Class 5 - A · Main Campus'), findsOneWidget);
    expect(find.text('Class 5 — A'), findsOneWidget);
    expect(find.textContaining('Winter timetable'), findsOneWidget);
    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Tue'), findsOneWidget);
    expect(find.text('Period 1'), findsOneWidget);
    expect(find.text('07:45 – 08:30'), findsOneWidget);
    expect(find.text('Mathematics'), findsOneWidget);
    expect(find.text('Sir Ali'), findsOneWidget);
  });

  testWidgets('switching days shows free periods', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ParentTimetableView(
          session: _parentSession(),
          service: _FakeTimetableService(_sampleData()),
          clock: () => DateTime(2026, 9, 14, 8),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tue'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.freePeriod), findsOneWidget);
    expect(find.text('Mathematics'), findsNothing);
  });

  testWidgets('shows timetable error and retry', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ParentTimetableView(
          session: _parentSession(),
          service: _FakeTimetableService(
            const ParentTimetableData(),
            error: const ApiException('Unable to load the timetable.'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to load the timetable.'), findsOneWidget);
    expect(find.text(AppStrings.retry), findsOneWidget);
  });
}
