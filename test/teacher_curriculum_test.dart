import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lmssystem/app/routes.dart';
import 'package:lmssystem/core/constants/app_strings.dart';
import 'package:lmssystem/core/network/api_client.dart';
import 'package:lmssystem/core/network/api_exception.dart';
import 'package:lmssystem/models/auth_session.dart';
import 'package:lmssystem/models/teacher_curriculum.dart';
import 'package:lmssystem/services/teacher_curriculum_service.dart';
import 'package:lmssystem/views/curriculum/teacher_my_weeks_detail_view.dart';
import 'package:lmssystem/views/curriculum/teacher_my_weeks_view.dart';
import 'package:lmssystem/views/dashboards/teacher_dashboard_view.dart';

AuthSession _teacherSession({int? branchId = 1}) {
  return AuthSession.fromJson({
    'token': 'teacher.token',
    'token_type': 'Bearer',
    'type': 'teacher',
    'school': {'id': '1', 'name': 'SLS', 'domain': 'sls.localhost'},
    'user': {
      'id': 58,
      'name': 'Tanveer',
      'last_name': 'Ahmed',
      'email': 'tanveer@example.com',
      'username': 'tanveer@example.com',
      'roles': ['Teacher'],
    },
    'profile': {
      'type': 'teacher',
      'teacher_id': 2,
      if (branchId != null) 'branch_id': branchId,
      if (branchId != null) 'branch_name': 'Avicenna Campus',
      'full_name': 'Sir Tanveer',
    },
  });
}

Map<String, dynamic> _apiEnvelope(Map<String, dynamic> payload, {String? message}) {
  return {
    'status': 'success',
    'message': message,
    'data': payload,
  };
}

Map<String, dynamic> _subjectsPayload() {
  return {
    'teacher': {'full_name': 'Sir Tanveer'},
    'classes': [
      {
        'class_id': 4,
        'class_name': 'Grade 5',
        'sections': [
          {
            'class_section_id': 10,
            'section_name': 'A',
            'subjects': [
              {
                'academic_session_id': 1,
                'session_name': '2026-27',
                'subject_id': 7,
                'subject_name': 'English',
                'has_published_plan': true,
                'plan_id': 3,
              },
              {
                'academic_session_id': 1,
                'session_name': '2026-27',
                'subject_id': 8,
                'subject_name': 'Mathematics',
                'has_published_plan': false,
                'plan_id': null,
              },
            ],
          },
        ],
      },
    ],
  };
}

Map<String, dynamic> _weeksPayload({String tab = 'open'}) {
  return {
    'tab': tab,
    'context': {
      'class_id': 4,
      'class_name': 'Grade 5',
      'class_section_id': 10,
      'section_name': 'A',
      'subject_id': 7,
      'subject_name': 'English',
      'academic_session_id': 1,
      'session_name': '2026-27',
    },
    'summary': {
      'open': tab == 'open' ? 1 : 0,
      'completed': tab == 'completed' ? 1 : 0,
      'total': 1,
      'progress_percent': tab == 'completed' ? 100 : 0,
    },
    'terms': [
      {
        'id': 2,
        'name': 'Term 1',
        'start_date': '2026-09-01',
        'end_date': '2026-11-30',
        'count': 1,
        'plan_content': '<p>Read chapter 1</p>',
        'weeks': [
          {
            'completion_id': 21,
            'week_number': 1,
            'week_title': 'Week 1 — Nouns',
            'week_start_date': '2026-09-01',
            'week_end_date': '2026-09-05',
            'status': tab == 'completed' ? 'completed' : 'pending',
            'status_label': tab == 'completed' ? 'Completed' : 'Pending',
            'notes': null,
            'due_by': '2026-09-05',
            'chapters': [
              {
                'title': 'Nouns',
                'description': '<p>Common and proper</p>',
                'topics': [
                  {
                    'title': 'Proper nouns',
                    'description': null,
                    'is_optional': false,
                  },
                  {
                    'title': 'Collective nouns',
                    'description': 'Group names',
                    'is_optional': true,
                  },
                ],
              },
            ],
          },
        ],
      },
    ],
  };
}

CurriculumSubjectSelection _englishSelection() {
  final data = TeacherCurriculumSubjects.fromJson(_subjectsPayload());
  return CurriculumSubjectSelection(
    classItem: data.classes.first,
    section: data.classes.first.sections.first,
    subject: data.classes.first.sections.first.subjects.first,
  );
}

class _FakeCurriculumService extends TeacherCurriculumService {
  _FakeCurriculumService({
    TeacherCurriculumSubjects? subjects,
    this.subjectsError,
  }) : subjects = subjects ?? TeacherCurriculumSubjects.fromJson(_subjectsPayload());

  TeacherCurriculumSubjects subjects;
  final Object? subjectsError;
  String lastTab = 'open';
  Map<String, dynamic>? lastUpdate;
  TeacherCurriculumWeeks Function(String tab)? weeksForTab;

  @override
  Future<TeacherCurriculumSubjects> fetchSubjects(AuthSession session) async {
    if (subjectsError != null) throw subjectsError!;
    return subjects;
  }

  @override
  Future<TeacherCurriculumWeeks> fetchWeeks(
    AuthSession session, {
    required CurriculumSubjectSelection selection,
    String tab = 'open',
  }) async {
    lastTab = tab;
    if (weeksForTab != null) return weeksForTab!(tab);
    return TeacherCurriculumWeeks.fromJson(_weeksPayload(tab: tab));
  }

  @override
  Future<CurriculumWeekUpdateResult> updateWeek(
    AuthSession session, {
    required int completionId,
    required String status,
    String? notes,
  }) async {
    lastUpdate = {
      'completion_id': completionId,
      'status': status,
      'notes': notes,
    };
    return CurriculumWeekUpdateResult(
      completionId: completionId,
      status: status,
      statusLabel: status == 'completed' ? 'Completed' : 'Not completed',
      notes: notes,
      message: 'Week updated.',
    );
  }
}

void main() {
  test('parses teaching subjects grouped by class and section', () {
    final data = TeacherCurriculumSubjects.fromJson(_subjectsPayload());

    expect(data.teacherName, 'Sir Tanveer');
    expect(data.classes, hasLength(1));
    expect(data.classes.first.title, 'Grade 5');
    expect(data.classes.first.sections.single.displayName, 'Section A');
    expect(data.classes.first.sections.single.subjects.map((s) => s.title).toList(), [
      'English',
      'Mathematics',
    ]);
    expect(data.classes.first.sections.single.subjects.first.hasPublishedPlan, isTrue);
    expect(data.classes.first.sections.single.subjects.last.hasPublishedPlan, isFalse);
  });

  test('parses open weeks with chapters, topics, and progress', () {
    final data = TeacherCurriculumWeeks.fromJson(_weeksPayload());

    expect(data.context?.subjectTitle, 'English');
    expect(data.context?.subtitle, 'Grade 5 · Section A · 2026-27');
    expect(data.summary.open, 1);
    expect(data.summary.progressPercent, 0);
    expect(data.terms.single.title, 'Term 1');
    expect(data.terms.single.planText, 'Read chapter 1');
    expect(data.terms.single.weeks.single.title, 'Week 1 — Nouns');
    expect(data.terms.single.weeks.single.topicCount, 2);
    expect(data.terms.single.weeks.single.chapters.single.topics.last.isOptional, isTrue);
    expect(displayCurriculumDate('2026-09-05'), '5 Sep 2026');
  });

  test('fetches subjects with the selected branch', () async {
    http.Request? captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode(_apiEnvelope(_subjectsPayload())),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final data = await TeacherCurriculumService(
      client: ApiClient(httpClient: client),
    ).fetchSubjects(_teacherSession());

    expect(captured, isNotNull);
    expect(captured!.method, 'GET');
    expect(captured!.url.path, '/api/mobile/teachers/curriculum/subjects');
    expect(captured!.url.queryParameters['domain'], 'sls.localhost');
    expect(captured!.url.queryParameters['branch_id'], '1');
    expect(captured!.headers['Authorization'], 'Bearer teacher.token');
    expect(data.classes, hasLength(1));
  });

  test('fetches weeks for a class, section, and subject', () async {
    http.Request? captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode(_apiEnvelope(_weeksPayload())),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final data = await TeacherCurriculumService(
      client: ApiClient(httpClient: client),
    ).fetchWeeks(
      _teacherSession(),
      selection: _englishSelection(),
      tab: 'open',
    );

    expect(captured, isNotNull);
    expect(captured!.method, 'GET');
    expect(captured!.url.path, '/api/mobile/teachers/curriculum/weeks');
    expect(captured!.url.queryParameters['session_id'], '1');
    expect(captured!.url.queryParameters['class_id'], '4');
    expect(captured!.url.queryParameters['class_section_id'], '10');
    expect(captured!.url.queryParameters['subject_id'], '7');
    expect(captured!.url.queryParameters['tab'], 'open');
    expect(data.terms.single.weeks.single.completionId, 21);
  });

  test('requires a selected branch before loading My Weeks', () async {
    expect(
      () => TeacherCurriculumService().fetchSubjects(_teacherSession(branchId: null)),
      throwsA(isA<ApiException>()),
    );
  });

  test('updates a week status for the current branch', () async {
    http.Request? captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode(_apiEnvelope(
          {
            'completion': {
              'id': 21,
              'status': 'completed',
              'status_label': 'Completed',
              'notes': 'Done in class',
            },
          },
          message: 'Week updated.',
        )),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final result = await TeacherCurriculumService(
      client: ApiClient(httpClient: client),
    ).updateWeek(
      _teacherSession(),
      completionId: 21,
      status: 'completed',
      notes: 'Done in class',
    );

    expect(captured, isNotNull);
    expect(captured!.method, 'POST');
    expect(captured!.url.path, '/api/mobile/teachers/curriculum/weeks/update');
    final body = jsonDecode(captured!.body) as Map<String, dynamic>;
    expect(body['domain'], 'sls.localhost');
    expect(body['branch_id'], '1');
    expect(body['completion_id'], 21);
    expect(body['status'], 'completed');
    expect(body['notes'], 'Done in class');
    expect(result.status, 'completed');
    expect(result.message, 'Week updated.');
  });

  testWidgets('shows curriculum subjects grouped by class and section', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TeacherMyWeeksView(
          session: _teacherSession(),
          service: _FakeCurriculumService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.myCurriculumSubjects), findsOneWidget);
    expect(find.text('Grade 5'), findsOneWidget);
    expect(find.text('Section A'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Mathematics'), findsOneWidget);
    expect(find.textContaining(AppStrings.planPublished), findsOneWidget);
    expect(find.textContaining(AppStrings.noPublishedPlan), findsOneWidget);
  });

  testWidgets('opens weeks for a subject and marks a week completed', (tester) async {
    final fake = _FakeCurriculumService();

    await tester.pumpWidget(
      MaterialApp(
        home: TeacherMyWeeksView(
          session: _teacherSession(),
          service: fake,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('my-weeks-subject-4-10-7')));
    await tester.pumpAndSettle();

    expect(find.byType(TeacherMyWeeksDetailView), findsOneWidget);
    expect(find.text('Week 1 — Nouns'), findsOneWidget);
    expect(find.text('Proper nouns'), findsOneWidget);
    expect(find.text(AppStrings.optional), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('my-weeks-complete-21')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('my-weeks-complete-21')));
    await tester.pumpAndSettle();

    expect(fake.lastUpdate?['completion_id'], 21);
    expect(fake.lastUpdate?['status'], 'completed');
    expect(find.text(AppStrings.weekUpdated), findsOneWidget);
  });

  testWidgets('completed tab loads completed weeks', (tester) async {
    final fake = _FakeCurriculumService();

    await tester.pumpWidget(
      MaterialApp(
        home: TeacherMyWeeksDetailView(
          session: _teacherSession(),
          selection: _englishSelection(),
          service: fake,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(fake.lastTab, 'open');
    expect(find.text('Pending'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('my-weeks-tab-completed')));
    await tester.pumpAndSettle();

    expect(fake.lastTab, 'completed');
    expect(find.text(AppStrings.weekStatusCompleted), findsWidgets);
  });

  testWidgets('tapping My Weeks opens the teacher curriculum screen', (tester) async {
    final session = _teacherSession();
    final fake = _FakeCurriculumService();

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.teacherMyWeeks) {
            return MaterialPageRoute(
              builder: (_) => TeacherMyWeeksView(
                session: session,
                service: fake,
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
    await tester.tap(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.text(AppStrings.myWeeks),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TeacherMyWeeksView), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });
}
