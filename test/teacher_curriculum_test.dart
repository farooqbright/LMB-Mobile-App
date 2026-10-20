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

CurriculumSubjectSelection _mathSelection() {
  final data = TeacherCurriculumSubjects.fromJson(_subjectsPayload());
  return CurriculumSubjectSelection(
    classItem: data.classes.first,
    section: data.classes.first.sections.first,
    subject: data.classes.first.sections.first.subjects.last,
  );
}

Map<String, dynamic> _mathItemsWeeksPayload() {
  return {
    'tab': 'open',
    'summary': {
      'pending': 1,
      'completed': 0,
      'total': 1,
      'progress_percent': 0,
    },
    'weeks': [
      {
        'completion_id': 21,
        'week_title': 'Week 1 — Nouns',
        'class_id': 4,
        'class_section_id': 10,
        'subject_id': 7,
        'status': 'pending',
        'items': [
          {
            'chapter': 'Nouns',
            'topic': 'Proper nouns',
            'details': 'Names of people and places',
          },
        ],
      },
      {
        'completion_id': 44,
        'week_title': 'Slot 1',
        'class_id': 4,
        'class_section_id': 10,
        'subject_id': 8,
        'status': 'pending',
        'items': [
          {
            'chapter': 'Whole Numbers',
            'topic': 'Place value',
            'details': 'Revise 6-digit numbers.',
          },
        ],
      },
    ],
  };
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

  test('parses curriculum details from week_count, dates, and details_text', () {
    final data = TeacherCurriculumWeeks.fromJson({
      'tab': 'open',
      'summary': {'pending': 1, 'completed': 0, 'total': 1, 'progress_percent': 0},
      'terms': [
        {
          'id': 2,
          'name': 'Term 1',
          'week_count': 1,
          'plan_text': 'Cover nouns and verbs',
          'weeks': [
            {
              'completion_id': 21,
              'week_number': 1,
              'week_title': 'Week 1',
              'start_date': '2026-09-01',
              'end_date': '2026-09-05',
              'status': 'pending',
              'details_text': 'Common nouns, proper nouns, and collective nouns.',
              'can_update': true,
              'chapters': [],
            },
          ],
        },
      ],
    });

    expect(data.summary.open, 1);
    expect(data.terms.single.count, 1);
    expect(data.terms.single.planText, 'Cover nouns and verbs');
    expect(data.terms.single.weeks.single.detailsText,
        'Common nouns, proper nouns, and collective nouns.');
    expect(data.terms.single.weeks.single.hasDetails, isTrue);
  });

  test('parses map-shaped terms and chapter item cards', () {
    final data = TeacherCurriculumWeeks.fromJson({
      'tab': 'open',
      'terms': {
        'Term 1': {
          'name': 'Term 1',
          'weeks': {
            '0': {
              'completion_id': 44,
              'week_title': 'Slot 1',
              'status': 'pending',
              'items': [
                {
                  'chapter': 'Whole Numbers',
                  'topic': 'Place value',
                  'details': 'Revise 6-digit numbers.',
                },
              ],
            },
          },
        },
      },
    });

    final week = data.terms.single.weeks.single;
    expect(week.title, 'Slot 1');
    expect(week.canUpdate, isTrue);
    expect(week.chapters.single.title, 'Whole Numbers');
    expect(week.chapters.single.topics.single.title, 'Place value');
    expect(week.chapters.single.topics.single.descriptionText, 'Revise 6-digit numbers.');
  });

  test('keeps Math weeks from a flat weeks list and drops other subjects', () {
    final data = TeacherCurriculumWeeks.fromJson(_mathItemsWeeksPayload())
        .forSelection(_mathSelection());

    expect(data.terms.single.weeks, hasLength(1));
    expect(data.terms.single.weeks.single.title, 'Slot 1');
    expect(data.terms.single.weeks.single.chapters.single.title, 'Whole Numbers');
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

  test('fetches Math weeks from a flat item-card payload', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode(_apiEnvelope(_mathItemsWeeksPayload())),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final data = await TeacherCurriculumService(
      client: ApiClient(httpClient: client),
    ).fetchWeeks(
      _teacherSession(),
      selection: _mathSelection(),
      tab: 'open',
    );

    expect(data.terms.single.weeks, hasLength(1));
    expect(data.terms.single.weeks.single.completionId, 44);
    expect(data.terms.single.weeks.single.chapters.single.title, 'Whole Numbers');
    expect(data.terms.single.weeks.single.chapters.single.topics.single.title, 'Place value');
    expect(data.terms.single.weeks.single.canUpdate, isTrue);
  });

  test('keeps slots when week class_id is missing or zero', () {
    final data = TeacherCurriculumWeeks.fromJson({
      'tab': 'open',
      'terms': [
        {
          'name': 'Term 1',
          'weeks': [
            {
              'completion_id': 44,
              'week_title': 'Slot 1',
              'class_id': 0,
              'class_section_id': 0,
              'subject_id': 0,
              'status': 'pending',
              'chapters': [
                {
                  'title': 'Whole Numbers',
                  'topics': [
                    {'title': 'Place value', 'description': 'Revise 6-digit numbers.'},
                  ],
                },
              ],
            },
          ],
        },
      ],
    }).forSelection(_mathSelection());

    expect(data.terms.single.weeks, hasLength(1));
    expect(data.terms.single.weeks.single.title, 'Slot 1');
  });

  testWidgets('opens completed slots when pending list is empty', (tester) async {
    final fake = _FakeCurriculumService();
    fake.weeksForTab = (tab) {
      if (tab == 'completed') {
        return TeacherCurriculumWeeks.fromJson(_weeksPayload(tab: 'completed'));
      }
      return TeacherCurriculumWeeks.fromJson({
        'tab': 'open',
        'summary': {
          'open': 0,
          'completed': 1,
          'total': 1,
          'progress_percent': 100,
        },
        'terms': [],
        'empty_message': 'No pending slots for this subject.',
      });
    };

    await tester.pumpWidget(
      MaterialApp(
        home: TeacherMyWeeksDetailView(
          session: _teacherSession(),
          selection: _mathSelection(),
          service: fake,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(fake.lastTab, 'completed');
    expect(find.text('Week 1 — Nouns'), findsOneWidget);
    expect(find.text('Proper nouns'), findsOneWidget);
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

  testWidgets('shows Math chapter, topic, details, and completion actions', (tester) async {
    final fake = _FakeCurriculumService();
    fake.weeksForTab = (_) => TeacherCurriculumWeeks.fromJson(_mathItemsWeeksPayload())
        .forSelection(_mathSelection());

    await tester.pumpWidget(
      MaterialApp(
        home: TeacherMyWeeksDetailView(
          session: _teacherSession(),
          selection: _mathSelection(),
          service: fake,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mathematics'), findsWidgets);
    expect(find.text('Slot 1'), findsOneWidget);
    expect(find.text(AppStrings.chapterLabel), findsOneWidget);
    expect(find.text('Whole Numbers'), findsOneWidget);
    expect(find.text(AppStrings.topicLabel), findsOneWidget);
    expect(find.text('Place value'), findsOneWidget);
    expect(find.text('Revise 6-digit numbers.'), findsOneWidget);
    expect(find.byKey(const ValueKey('my-weeks-complete-44')), findsOneWidget);
    expect(find.byKey(const ValueKey('my-weeks-not-complete-44')), findsOneWidget);
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
    expect(find.text(AppStrings.openWeeks), findsWidgets);

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
