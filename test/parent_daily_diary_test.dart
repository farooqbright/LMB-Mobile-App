import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lmssystem/core/constants/app_strings.dart';
import 'package:lmssystem/core/network/api_exception.dart';
import 'package:lmssystem/models/auth_session.dart';
import 'package:lmssystem/models/teacher_attendance.dart';
import 'package:lmssystem/parent/controllers/parent_daily_diary_controller.dart';
import 'package:lmssystem/parent/models/parent_daily_diary.dart';
import 'package:lmssystem/parent/screens/parent_daily_diary_view.dart';
import 'package:lmssystem/parent/services/parent_daily_diary_service.dart';

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

class _FakeDiaryService extends ParentDailyDiaryService {
  _FakeDiaryService(this.data, {this.error});

  final ParentDailyDiaryData data;
  final Object? error;
  ParentDailyDiaryQuery? lastQuery;
  var fetches = 0;

  @override
  Future<ParentDailyDiaryData> fetch(
    AuthSession session, {
    ParentDailyDiaryQuery query = const ParentDailyDiaryQuery(),
  }) async {
    fetches += 1;
    lastQuery = query;
    if (error != null) throw error!;
    return data;
  }
}

ParentDailyDiaryData _sampleData() {
  return ParentDailyDiaryData.fromJson({
    'student': {
      'student_id': 11,
      'full_name': 'Ahmed Ali',
      'class_name': 'Class 5',
      'section_name': 'A',
      'branch_name': 'Main Campus',
    },
    'period': 'today',
    'date': '2026-09-18',
    'date_from': '2026-09-18',
    'date_to': '2026-09-18',
    'range_label': 'Today · 18 Sep 2026',
    'has_enrollment': true,
    'days_count': 1,
    'subjects_count': 2,
    'days': [
      {
        'date': '2026-09-18',
        'date_label': '18 Sep 2026',
        'weekday': 'Friday',
        'entries': [
          {
            'id': 1,
            'subject_id': 4,
            'subject_name': 'Mathematics',
            'work_done': 'Fractions chapter 4',
            'homework': 'Exercise 4.2',
          },
          {
            'id': 2,
            'subject_id': 5,
            'subject_name': 'English',
            'work_done': 'Comprehension',
            'homework': null,
          },
        ],
      },
    ],
  });
}

void main() {
  test('parses student diary days and entries', () {
    final data = _sampleData();

    expect(data.studentName, 'Ahmed Ali');
    expect(data.classLabel, 'Class 5 - A');
    expect(data.rangeLabel, 'Today · 18 Sep 2026');
    expect(data.days, hasLength(1));
    expect(data.days.first.weekday, 'Friday');
    expect(data.days.first.entries, hasLength(2));
    expect(data.days.first.entries.first.displaySubject, 'Mathematics');
    expect(data.days.first.entries.first.displayWorkDone, 'Fractions chapter 4');
    expect(data.days.first.entries.last.displayHomework, '—');
  });

  test('defaults the diary filter to today', () {
    final controller = ParentDailyDiaryController(
      session: _parentSession(),
      clock: () => DateTime(2026, 9, 18),
    );

    expect(controller.period, ParentDiaryPeriod.today);
    expect(isoAttendanceDate(controller.selectedDate), '2026-09-18');
    expect(controller.query.period, 'today');
    expect(controller.query.date, '2026-09-18');
  });

  test('last week filter sends last_week', () async {
    final fake = _FakeDiaryService(_sampleData());
    final controller = ParentDailyDiaryController(
      session: _parentSession(),
      service: fake,
      clock: () => DateTime(2026, 9, 18),
    );

    await controller.selectPeriod(ParentDiaryPeriod.lastWeek);

    expect(fake.fetches, 1);
    expect(fake.lastQuery?.period, 'last_week');
    expect(controller.rangeLabel, 'Last week · 07 Sep 2026 — 13 Sep 2026');
  });

  testWidgets('shows selected student diary for today', (tester) async {
    final fake = _FakeDiaryService(_sampleData());

    await tester.pumpWidget(
      MaterialApp(
        home: ParentDailyDiaryView(
          session: _parentSession(),
          service: fake,
          clock: () => DateTime(2026, 9, 18),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(fake.lastQuery?.period, 'today');
    expect(find.text(AppStrings.dailyDiary), findsOneWidget);
    expect(find.text('Ahmed Ali'), findsOneWidget);
    expect(find.text('Class 5 - A · Main Campus'), findsOneWidget);
    expect(find.text(AppStrings.attendanceToday), findsOneWidget);
    expect(find.text(AppStrings.lastWeek), findsOneWidget);
    expect(find.text(AppStrings.searchByDate), findsOneWidget);
    expect(find.text(AppStrings.search), findsOneWidget);
    expect(find.text('Showing: Today · 18 Sep 2026 · 1 day · 2 subjects'), findsOneWidget);
    expect(find.text('18 Sep 2026'), findsOneWidget);
    expect(find.text('Friday'), findsOneWidget);
    expect(find.text('Mathematics'), findsOneWidget);
    expect(find.text('Fractions chapter 4'), findsOneWidget);
    expect(find.text('Exercise 4.2'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Comprehension'), findsOneWidget);
  });

  testWidgets('last week filter reloads diary entries', (tester) async {
    final fake = _FakeDiaryService(_sampleData());

    await tester.pumpWidget(
      MaterialApp(
        home: ParentDailyDiaryView(
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
    expect(fake.lastQuery?.period, 'last_week');
  });

  testWidgets('search by date uses the selected date', (tester) async {
    final fake = _FakeDiaryService(_sampleData());

    await tester.pumpWidget(
      MaterialApp(
        home: ParentDailyDiaryView(
          session: _parentSession(),
          service: fake,
          clock: () => DateTime(2026, 9, 18),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.search));
    await tester.pumpAndSettle();

    expect(fake.fetches, 2);
    expect(fake.lastQuery?.period, 'date');
    expect(fake.lastQuery?.date, '2026-09-18');
  });

  testWidgets('shows diary error and retry', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ParentDailyDiaryView(
          session: _parentSession(),
          service: _FakeDiaryService(
            const ParentDailyDiaryData(),
            error: const ApiException('Unable to load the daily diary.'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to load the daily diary.'), findsOneWidget);
    expect(find.text(AppStrings.retry), findsOneWidget);
  });
}
