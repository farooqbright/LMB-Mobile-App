import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lmssystem/app/routes.dart';
import 'package:lmssystem/controllers/teacher_timetable_controller.dart';
import 'package:lmssystem/core/constants/app_strings.dart';
import 'package:lmssystem/core/network/api_client.dart';
import 'package:lmssystem/core/network/api_exception.dart';
import 'package:lmssystem/models/auth_session.dart';
import 'package:lmssystem/models/teacher_timetable.dart';
import 'package:lmssystem/services/teacher_timetable_service.dart';
import 'package:lmssystem/views/dashboards/teacher_dashboard_view.dart';
import 'package:lmssystem/views/timetable/teacher_timetable_view.dart';

AuthSession _teacherSession() {
  return AuthSession.fromJson({
    'token': 'teacher.token',
    'token_type': 'Bearer',
    'type': 'teacher',
    'school': {'id': '1', 'name': 'SLS', 'domain': 'sls.localhost'},
    'user': {
      'id': 58,
      'name': 'Saad',
      'last_name': 'Ahmed',
      'email': 'saad_av@sciencelyceum.com',
      'username': 'saad_av@sciencelyceum.com',
      'roles': ['Teacher'],
      'avatar_url': null,
    },
    'profile': {
      'type': 'teacher',
      'teacher_id': 2,
      'branch_id': 1,
      'branch_name': 'Avicenna Campus',
      'full_name': 'Sir Saad',
    },
  });
}

Map<String, dynamic> _samplePayload() {
  return {
    'teacher': {
      'user_id': 58,
      'full_name': 'Sir Saad',
      'email': 'saad_av@sciencelyceum.com',
      'avatar_url': null,
    },
    'branch': {
      'branch_id': 1,
      'branch_name': 'Avicenna Campus',
    },
    'schedules': [
          {
            'timetable_id': 3,
            'name': '6th To 10th',
            'branch_id': 1,
            'branch_name': 'Avicenna Campus',
            'session': {'id': 1, 'name': '2026'},
            'slot_count': 80,
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
            'slots': [
              {
                'id': 1816,
                'day': 1,
                'day_label': 'Monday',
                'period_id': 7,
                'period_name': 'Period 1',
                'start_time': '07:45',
                'end_time': '08:30',
                'class_id': 9,
                'class_name': 'GRADE PRE-9th',
                'section_id': 1,
                'section_name': 'ARTS',
                'subject_id': 4,
                'subject_name': 'Maths',
                'branch_id': 1,
                'branch_name': 'Avicenna Campus',
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
                        'class_name': 'GRADE PRE-9th',
                        'section_name': 'ARTS',
                        'subject_name': 'Maths',
                      },
                      {
                        'class_name': 'GRADE PRE-9th',
                        'section_name': 'BIOLOGY SCIENCE',
                        'subject_name': 'Maths',
                      },
                    ],
                  },
                  {'day': 2, 'label': 'Tuesday', 'lessons': []},
                ],
              },
            ],
          },
    ],
  };
}

class _FakeTimetableService extends TeacherTimetableService {
  _FakeTimetableService(this.data, {this.error});

  final TeacherTimetableData data;
  final Object? error;

  @override
  Future<TeacherTimetableData> fetch(AuthSession session) async {
    if (error != null) {
      throw error!;
    }
    return data;
  }
}

void main() {
  test('parses teacher timetable payload for the selected branch', () {
    final data = TeacherTimetableData.fromJson(_samplePayload());

    expect(data.teacher.fullName, 'Sir Saad');
    expect(data.branches, hasLength(1));
    expect(data.branches.first.title, 'Avicenna Campus');
    expect(data.schedules, hasLength(1));

    final schedule = data.branches.first.schedules.single;
    expect(schedule.title, '6th To 10th');
    expect(schedule.sessionLabel, 'Session 2026');
    expect(schedule.slotCount, 80);
    expect(schedule.defaultDay(weekday: 1), 1);

    final monday = schedule.cellsForDay(1).single;
    expect(monday.title, 'Period 1');
    expect(monday.timeRange, '07:45 – 08:30');
    expect(monday.lessons, hasLength(2));
    expect(monday.lessons.first.subtitle, 'GRADE PRE-9th · ARTS');

    final tuesday = schedule.cellsForDay(2).single;
    expect(tuesday.isFree, isTrue);
  });

  test('highlights current or upcoming period from the time slot', () {
    final cells = [
      const SchedulePeriodCell(
        periodId: 7,
        periodName: 'Period 1',
        startTime: '07:45',
        endTime: '08:30',
      ),
      const SchedulePeriodCell(
        periodId: 8,
        periodName: 'Period 2',
        startTime: '08:30',
        endTime: '09:10',
      ),
    ];

    PeriodFocus? at(int hour, int minute, {int day = 1}) {
      return PeriodFocus.resolve(
        cells: cells,
        now: DateTime(2026, 9, 14, hour, minute),
        selectedDay: day,
      );
    }

    expect(at(7, 10)?.cell.periodName, 'Period 1');
    expect(at(7, 10)?.kind, PeriodFocusKind.upcoming);
    expect(at(8, 0)?.kind, PeriodFocusKind.now);
    expect(at(8, 0)?.cell.periodName, 'Period 1');
    expect(at(8, 30)?.cell.periodName, 'Period 2');
    expect(at(8, 30)?.kind, PeriodFocusKind.now);
    expect(at(9, 10), isNull);
    expect(at(8, 0, day: 2), isNull);
  });

  test('uses the device clock when none is provided', () {
    final controller = TeacherTimetableController(session: _teacherSession());
    expect(controller.now, isA<DateTime>());
  });

  test('fetches timetable with bearer token, domain and selected branch', () async {
    http.Request? captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode({
          'status': 'success',
          'message': null,
          'data': _samplePayload(),
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final data = await TeacherTimetableService(
      client: ApiClient(httpClient: client),
    ).fetch(_teacherSession());

    expect(captured, isNotNull);
    expect(captured!.method, 'GET');
    expect(captured!.url.path, '/api/mobile/teachers/my-timetable');
    expect(captured!.url.queryParameters['domain'], 'sls.localhost');
    expect(captured!.url.queryParameters['branch_id'], '1');
    expect(captured!.headers['Authorization'], 'Bearer teacher.token');
    expect(data.branches.first.title, 'Avicenna Campus');
    expect(data.branches, hasLength(1));
  });

  test('sends the selected campus as branch_id', () async {
    http.Request? captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode({
          'status': 'success',
          'message': null,
          'data': {
            'teacher': {'full_name': 'Sir Saad'},
            'branch': {'branch_id': 2, 'branch_name': 'Ibn Sina Campus'},
            'schedules': const [],
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final session = AuthSession.fromJson({
      'token': 'teacher.token',
      'token_type': 'Bearer',
      'type': 'teacher',
      'school': {'id': '1', 'name': 'SLS', 'domain': 'sls.localhost'},
      'user': {'id': 58, 'name': 'Saad', 'roles': ['Teacher']},
      'selected_branch_id': 2,
      'profile': {
        'type': 'teacher',
        'teacher_id': 2,
        'branch_id': 1,
        'branch_name': 'Avicenna Campus',
        'full_name': 'Sir Saad',
        'branches': [
          {'branch_id': 1, 'branch_name': 'Avicenna Campus'},
          {'branch_id': 2, 'branch_name': 'Ibn Sina Campus'},
        ],
      },
    });

    final data = await TeacherTimetableService(
      client: ApiClient(httpClient: client),
    ).fetch(session);

    expect(captured!.url.queryParameters['branch_id'], '2');
    expect(data.branches, hasLength(1));
    expect(data.branches.first.title, 'Ibn Sina Campus');
  });

  test('keeps only the requested branch from a multi-campus payload', () {
    final data = TeacherTimetableData.fromJson({
      'teacher': {'full_name': 'Sir Saad'},
      'branches': [
        {'branch_id': 1, 'branch_name': 'Avicenna Campus', 'schedules': const []},
        {'branch_id': 2, 'branch_name': 'Ibn Sina Campus', 'schedules': const []},
      ],
    }).forBranch(2);

    expect(data.branches, hasLength(1));
    expect(data.branches.single.title, 'Ibn Sina Campus');
  });

  test('requires a selected branch id', () async {
    final session = AuthSession.fromJson({
      'token': 'teacher.token',
      'token_type': 'Bearer',
      'type': 'teacher',
      'school': {'id': '1', 'name': 'SLS', 'domain': 'sls.localhost'},
      'user': {'id': 58, 'name': 'Saad', 'roles': ['Teacher']},
      'profile': {
        'type': 'teacher',
        'full_name': 'Sir Saad',
        'branches': [
          {'branch_id': 1, 'branch_name': 'Avicenna Campus'},
          {'branch_id': 2, 'branch_name': 'Ibn Sina Campus'},
        ],
      },
    });

    expect(session.activeBranchId, isNull);

    await expectLater(
      TeacherTimetableService(
        client: ApiClient(
          httpClient: MockClient((_) async => http.Response('{}', 500)),
        ),
      ).fetch(session),
      throwsA(isA<ApiException>()),
    );
  });

  testWidgets('tapping My Timetable opens branch schedules', (tester) async {
    final session = _teacherSession();
    final fake = _FakeTimetableService(TeacherTimetableData.fromJson(_samplePayload()));

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.teacherTimetable) {
            return MaterialPageRoute(
              builder: (_) => TeacherTimetableView(
                session: session,
                service: fake,
                clock: () => DateTime(2026, 9, 14, 8, 0),
              ),
              settings: settings,
            );
          }
          return AppRoutes.onGenerateRoute(settings);
        },
        home: TeacherDashboardView(session: session),
      ),
    );

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.myTimetable));
    await tester.pumpAndSettle();

    expect(find.byType(TeacherTimetableView), findsOneWidget);
    expect(find.text('Avicenna Campus'), findsOneWidget);
    expect(find.text('6th To 10th'), findsOneWidget);
    expect(find.text('Session 2026 · 80 classes'), findsOneWidget);
    expect(find.text('Period 1'), findsOneWidget);
    expect(find.text('07:45 – 08:30'), findsOneWidget);
    expect(find.text('Maths'), findsNWidgets(2));
    expect(find.text('GRADE PRE-9th · ARTS'), findsOneWidget);
    expect(find.text('GRADE PRE-9th · BIOLOGY SCIENCE'), findsOneWidget);
    expect(find.text(AppStrings.periodNow), findsOneWidget);

    await tester.tap(find.text('Tue'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.freePeriod), findsOneWidget);
    expect(find.text(AppStrings.periodNow), findsNothing);
  });

  testWidgets('highlights the next period before it starts', (tester) async {
    final session = _teacherSession();
    final fake = _FakeTimetableService(TeacherTimetableData.fromJson(_samplePayload()));

    await tester.pumpWidget(
      MaterialApp(
        home: TeacherTimetableView(
          session: session,
          service: fake,
          clock: () => DateTime(2026, 9, 14, 7, 10),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.periodUpNext), findsOneWidget);
    expect(find.text(AppStrings.periodNow), findsNothing);
  });

  testWidgets('does not highlight after the last period', (tester) async {
    final session = _teacherSession();
    final fake = _FakeTimetableService(TeacherTimetableData.fromJson(_samplePayload()));

    await tester.pumpWidget(
      MaterialApp(
        home: TeacherTimetableView(
          session: session,
          service: fake,
          clock: () => DateTime(2026, 9, 14, 18, 0),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.periodNow), findsNothing);
    expect(find.text(AppStrings.periodUpNext), findsNothing);
  });

  testWidgets('shows empty timetable message', (tester) async {
    final session = _teacherSession();
    final fake = _FakeTimetableService(
      const TeacherTimetableData(
        teacher: TimetableTeacher(fullName: 'Sir Saad'),
        branches: [],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TeacherTimetableView(session: session, service: fake),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.noTimetable), findsOneWidget);
  });

  testWidgets('shows API error and retry', (tester) async {
    final session = _teacherSession();
    final fake = _FakeTimetableService(
      const TeacherTimetableData(
        teacher: TimetableTeacher(),
        branches: [],
      ),
      error: const ApiException('No teacher profile is linked to this login.'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TeacherTimetableView(session: session, service: fake),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No teacher profile is linked to this login.'), findsOneWidget);
    expect(find.text(AppStrings.retry), findsOneWidget);
  });
}
