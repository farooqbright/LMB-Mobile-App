import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lmssystem/core/constants/app_strings.dart';
import 'package:lmssystem/core/network/api_client.dart';
import 'package:lmssystem/models/auth_session.dart';
import 'package:lmssystem/parent/models/parent_curriculum.dart';
import 'package:lmssystem/parent/screens/parent_curriculum_detail_view.dart';
import 'package:lmssystem/parent/screens/parent_curriculum_view.dart';
import 'package:lmssystem/parent/services/parent_curriculum_service.dart';
import 'package:lmssystem/models/teacher_curriculum.dart';

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

Map<String, dynamic> _apiEnvelope(Map<String, dynamic> payload) {
  return {
    'status': 'success',
    'data': payload,
  };
}

Map<String, dynamic> _subjectsPayload() {
  return {
    'student': {
      'student_id': 11,
      'full_name': 'Ahmed Ali',
      'class_name': 'Class 5',
      'section_name': 'A',
      'branch_name': 'Main Campus',
    },
    'has_enrollment': true,
    'class': {
      'id': 4,
      'name': 'Class 5',
      'section_id': 10,
      'section_name': 'A',
      'academic_session_id': 1,
      'session_name': '2026-27',
    },
    'subjects': [
      {
        'subject_id': 8,
        'subject_name': 'Mathematics',
        'has_plan': true,
        'plan_id': 3,
        'total': 2,
        'completed': 1,
        'pending': 1,
        'progress_percent': 50,
      },
      {
        'subject_id': 7,
        'subject_name': 'English',
        'has_plan': false,
        'plan_id': null,
        'total': 0,
        'completed': 0,
        'pending': 0,
        'progress_percent': 0,
      },
    ],
  };
}

Map<String, dynamic> _weeksPayload({String tab = 'open'}) {
  return {
    'tab': tab,
    'context': {
      'class_name': 'Class 5',
      'section_name': 'A',
      'subject_id': 8,
      'subject_name': 'Mathematics',
      'session_name': '2026-27',
    },
    'summary': {
      'open': tab == 'open' ? 1 : 0,
      'completed': tab == 'completed' ? 1 : 0,
      'total': 1,
      'progress_percent': tab == 'completed' ? 100 : 50,
    },
    'terms': [
      {
        'id': 2,
        'name': 'Term 1',
        'week_count': 1,
        'weeks': [
          {
            'completion_id': 44,
            'week_number': 1,
            'week_title': 'Slot 1',
            'status': tab == 'completed' ? 'completed' : 'pending',
            'status_label': tab == 'completed' ? 'Completed' : 'Pending',
            'can_update': false,
            'chapters': [
              {
                'title': 'Whole Numbers',
                'topics': [
                  {
                    'title': 'Place value',
                    'description': 'Revise 6-digit numbers.',
                    'is_optional': false,
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

class _FakeCurriculumService extends ParentCurriculumService {
  _FakeCurriculumService({
    ParentCurriculumSubjects? subjects,
    this.subjectsError,
  }) : subjects = subjects ?? ParentCurriculumSubjects.fromJson(_subjectsPayload());

  ParentCurriculumSubjects subjects;
  final Object? subjectsError;
  String lastTab = 'open';

  @override
  Future<ParentCurriculumSubjects> fetchSubjects(AuthSession session) async {
    if (subjectsError != null) throw subjectsError!;
    return subjects;
  }

  @override
  Future<TeacherCurriculumWeeks> fetchWeeks(
    AuthSession session, {
    required int subjectId,
    String tab = 'open',
  }) async {
    lastTab = tab;
    return TeacherCurriculumWeeks.fromJson(_weeksPayload(tab: tab));
  }
}

void main() {
  test('parses parent curriculum subjects and progress', () {
    final data = ParentCurriculumSubjects.fromJson(_subjectsPayload());

    expect(data.studentName, 'Ahmed Ali');
    expect(data.classLabel, 'Class 5 - A');
    expect(data.sessionName, '2026-27');
    expect(data.subjects, hasLength(2));
    expect(data.subjects.first.title, 'Mathematics');
    expect(data.subjects.first.hasPlan, isTrue);
    expect(data.subjects.first.progressLine, '1 completed · 1 pending · 50%');
    expect(data.subjects.last.hasPlan, isFalse);
  });

  test('parses parent curriculum slots with chapter and topic', () {
    final data = TeacherCurriculumWeeks.fromJson(_weeksPayload());

    expect(data.context?.subjectTitle, 'Mathematics');
    expect(data.terms.single.weeks.single.title, 'Slot 1');
    expect(data.terms.single.weeks.single.canUpdate, isFalse);
    expect(data.terms.single.weeks.single.chapters.single.title, 'Whole Numbers');
    expect(data.terms.single.weeks.single.chapters.single.topics.single.title, 'Place value');
  });

  test('fetches parent subjects for the selected student', () async {
    http.Request? captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode(_apiEnvelope(_subjectsPayload())),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final data = await ParentCurriculumService(
      client: ApiClient(httpClient: client),
    ).fetchSubjects(_parentSession());

    expect(captured!.method, 'GET');
    expect(captured!.url.path, '/api/mobile/parents/students/curriculum');
    expect(captured!.url.queryParameters['student_id'], '11');
    expect(captured!.url.queryParameters['domain'], 'sls.localhost');
    expect(data.subjects.first.title, 'Mathematics');
  });

  test('fetches parent weeks for a subject', () async {
    http.Request? captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode(_apiEnvelope(_weeksPayload())),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final data = await ParentCurriculumService(
      client: ApiClient(httpClient: client),
    ).fetchWeeks(_parentSession(), subjectId: 8, tab: 'open');

    expect(captured!.url.path, '/api/mobile/parents/students/curriculum/show');
    expect(captured!.url.queryParameters['student_id'], '11');
    expect(captured!.url.queryParameters['subject_id'], '8');
    expect(captured!.url.queryParameters['tab'], 'open');
    expect(data.terms.single.weeks.single.title, 'Slot 1');
  });

  testWidgets('shows parent curriculum subjects', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ParentCurriculumView(
          session: _parentSession(),
          service: _FakeCurriculumService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ahmed Ali'), findsOneWidget);
    expect(find.text('Mathematics'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text(AppStrings.viewCurriculum), findsOneWidget);
    expect(find.text(AppStrings.noCurriculumYet), findsOneWidget);
    expect(find.text('1 completed · 1 pending · 50%'), findsOneWidget);
  });

  testWidgets('opens Math slots with chapter and topic', (tester) async {
    final fake = _FakeCurriculumService();

    await tester.pumpWidget(
      MaterialApp(
        home: ParentCurriculumView(
          session: _parentSession(),
          service: fake,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('parent-curriculum-subject-8')));
    await tester.pumpAndSettle();

    expect(find.byType(ParentCurriculumDetailView), findsOneWidget);
    expect(find.text('Slot 1'), findsOneWidget);
    expect(find.text('Whole Numbers'), findsOneWidget);
    expect(find.text('Place value'), findsOneWidget);
    expect(find.text('Revise 6-digit numbers.'), findsOneWidget);
    expect(find.text(AppStrings.updateStatus), findsNothing);
  });
}
