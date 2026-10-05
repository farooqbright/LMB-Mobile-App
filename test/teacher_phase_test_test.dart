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
import 'package:lmssystem/models/teacher_exam.dart';
import 'package:lmssystem/services/teacher_phase_test_service.dart';
import 'package:lmssystem/views/dashboards/teacher_dashboard_view.dart';
import 'package:lmssystem/views/exams/teacher_exam_detail_view.dart';
import 'package:lmssystem/views/exams/teacher_exam_marks_view.dart';
import 'package:lmssystem/views/exams/teacher_exam_module_copy.dart';
import 'package:lmssystem/views/exams/teacher_exams_view.dart';

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

Map<String, dynamic> _phaseTestsPayload() {
  return {
    'teacher': {'full_name': 'Sir Tanveer'},
    'session': {'id': 1, 'name': '2026-27', 'status': 'Active'},
    'sessions': [
      {'id': 1, 'name': '2026-27', 'status': 'Active'},
    ],
    'exams': [
      {
        'id': 8,
        'name': 'First Phase',
        'status': 'published',
        'status_label': 'Published',
        'academic_session_id': 1,
        'session_name': '2026-27',
        'start_date': '2026-09-01',
        'end_date': '2026-09-10',
        'datesheet_count': 1,
        'markable_count': 2,
      },
    ],
  };
}

Map<String, dynamic> _phaseTestShowPayload() {
  return {
    'exam': {
      'id': 8,
      'name': 'First Phase',
      'status': 'published',
      'status_label': 'Published',
      'academic_session_id': 1,
      'session_name': '2026-27',
      'start_date': '2026-09-01',
      'end_date': '2026-09-10',
      'datesheet_count': 1,
      'markable_count': 2,
      'datesheets': [
        {
          'id': 3,
          'name': 'Written Papers',
          'subject_count': 2,
          'classes': [
            {
              'class_id': 4,
              'class_name': 'Grade 5',
              'sections': [
                {
                  'class_section_id': 10,
                  'section_name': 'A',
                  'subject_count': 2,
                },
              ],
            },
          ],
        },
      ],
    },
  };
}

Map<String, dynamic> _marksPayload() {
  return {
    'exam': {'id': 8, 'name': 'First Phase', 'session_name': '2026-27'},
    'datesheet': {'id': 3, 'name': 'Written Papers'},
    'class': {
      'class_id': 4,
      'class_name': 'Grade 5',
      'class_section_id': 10,
      'section_name': 'A',
    },
    'subjects': [
      {
        'id': 21,
        'subject_id': 9,
        'subject_name': 'Mathematics',
        'exam_date': '2026-09-02',
        'total_marks': 100,
      },
    ],
    'students': [
      {
        'id': 21,
        'full_name': 'Ali Khan',
        'roll_number': '05',
        'marks': [
          {'item_id': 21, 'marks_obtained': 80, 'is_absent': false},
        ],
      },
      {
        'id': 22,
        'full_name': 'Sara Ahmed',
        'roll_number': '12',
        'marks': [
          {'item_id': 21, 'marks_obtained': null, 'is_absent': false},
        ],
      },
    ],
  };
}

Map<String, dynamic> _apiEnvelope(Map<String, dynamic> payload, {String? message}) {
  return {
    'status': 'success',
    'message': message,
    'data': payload,
  };
}

class _FakePhaseTestService extends TeacherPhaseTestService {
  _FakePhaseTestService({
    TeacherExamList? exams,
    TeacherExamSummary? exam,
    TeacherExamMarksGrid? marks,
    this.examsError,
  })  : exams = exams ?? TeacherExamList.fromJson(_phaseTestsPayload()),
        exam = exam ??
            TeacherExamSummary.fromJson(
              _phaseTestShowPayload()['exam'] as Map<String, dynamic>,
            ),
        marks = marks ?? TeacherExamMarksGrid.fromJson(_marksPayload());

  TeacherExamList exams;
  TeacherExamSummary exam;
  TeacherExamMarksGrid marks;
  Object? examsError;
  Map<String, dynamic>? lastSave;

  @override
  Future<TeacherExamList> fetchExams(
    AuthSession session, {
    int? academicSessionId,
    int page = 1,
    int perPage = 25,
  }) async {
    if (examsError != null) throw examsError!;
    return exams;
  }

  @override
  Future<TeacherExamSummary> fetchExam(
    AuthSession session, {
    required int examId,
  }) async {
    return exam;
  }

  @override
  Future<TeacherExamMarksGrid> fetchMarks(
    AuthSession session, {
    required int examId,
    required int datesheetId,
    required int classId,
    required int classSectionId,
  }) async {
    return marks;
  }

  @override
  Future<TeacherExamSaveResult> saveMarks(
    AuthSession session, {
    required int examId,
    required int datesheetId,
    required int classId,
    required int classSectionId,
    required List<Map<String, dynamic>> totals,
    required List<Map<String, dynamic>> entries,
  }) async {
    lastSave = {
      'phase_exam_id': examId,
      'datesheet_id': datesheetId,
      'class_id': classId,
      'class_section_id': classSectionId,
      'totals': totals,
      'entries': entries,
    };
    return const TeacherExamSaveResult(
      saved: 2,
      message: 'Marks saved (2 entries).',
    );
  }
}

void main() {
  test('fetches phase tests with the selected branch', () async {
    http.Request? captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode(_apiEnvelope(_phaseTestsPayload())),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final data = await TeacherPhaseTestService(
      client: ApiClient(httpClient: client),
    ).fetchExams(_teacherSession());

    expect(captured, isNotNull);
    expect(captured!.method, 'GET');
    expect(captured!.url.path, '/api/mobile/teachers/phase-tests');
    expect(captured!.url.queryParameters['domain'], 'sls.localhost');
    expect(captured!.url.queryParameters['branch_id'], '1');
    expect(captured!.headers['Authorization'], 'Bearer teacher.token');
    expect(data.exams.single.title, 'First Phase');
  });

  test('requires a selected branch before loading phase tests', () async {
    expect(
      () => TeacherPhaseTestService().fetchExams(_teacherSession(branchId: null)),
      throwsA(isA<ApiException>()),
    );
  });

  test('saves a phase test marks grid for taught subjects', () async {
    http.Request? captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode(_apiEnvelope({'saved': 2}, message: 'Marks saved (2 entries).')),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final result = await TeacherPhaseTestService(
      client: ApiClient(httpClient: client),
    ).saveMarks(
      _teacherSession(),
      examId: 8,
      datesheetId: 3,
      classId: 4,
      classSectionId: 10,
      totals: const [
        {'item_id': 21, 'total_marks': 100},
      ],
      entries: const [
        {'student_id': 21, 'item_id': 21, 'marks_obtained': 80, 'is_absent': false},
        {'student_id': 22, 'item_id': 21, 'marks_obtained': null, 'is_absent': true},
      ],
    );

    expect(captured, isNotNull);
    expect(captured!.method, 'POST');
    expect(captured!.url.path, '/api/mobile/teachers/phase-tests/marks');
    final body = jsonDecode(captured!.body) as Map<String, dynamic>;
    expect(body['domain'], 'sls.localhost');
    expect(body['branch_id'], '1');
    expect(body['phase_exam_id'], 8);
    expect(body['exam_id'], isNull);
    expect(body['datesheet_id'], 3);
    expect(result.saved, 2);
  });

  testWidgets('shows phase tests and opens nested sections', (tester) async {
    final fake = _FakePhaseTestService();

    await tester.pumpWidget(
      MaterialApp(
        home: TeacherExamsView(
          session: _teacherSession(),
          service: fake,
          copy: TeacherExamModuleCopy.phaseTests,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.testsAndHw), findsOneWidget);
    expect(find.text('First Phase'), findsOneWidget);
    expect(find.text('Published'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('phase-test-8')));
    await tester.pumpAndSettle();

    expect(find.byType(TeacherExamDetailView), findsOneWidget);
    expect(find.text('Written Papers'), findsOneWidget);
    expect(find.text('Grade 5'), findsOneWidget);
    expect(find.text('Section A'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('phase-test-class-4-section-10')));
    await tester.pumpAndSettle();

    expect(find.byType(TeacherExamMarksView), findsOneWidget);
    expect(find.text('1. Ali Khan'), findsOneWidget);
    expect(find.text('2. Sara Ahmed'), findsOneWidget);
    expect(find.text('Mathematics'), findsWidgets);
  });

  testWidgets('saves phase test marks from the sheet', (tester) async {
    final fake = _FakePhaseTestService();

    await tester.pumpWidget(
      MaterialApp(
        home: TeacherExamMarksView(
          session: _teacherSession(),
          examId: 8,
          datesheetId: 3,
          classId: 4,
          classSectionId: 10,
          service: fake,
          copy: TeacherExamModuleCopy.phaseTests,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.absentShort).last);
    await tester.tap(find.text(AppStrings.saveMarks));
    await tester.pump();

    expect(fake.lastSave, isNotNull);
    expect(fake.lastSave!['phase_exam_id'], 8);
    expect(fake.lastSave!['entries'].last['is_absent'], isTrue);
    expect(find.text('Marks saved (2 entries).'), findsOneWidget);
  });

  testWidgets('tapping Phase Tests opens the teacher phase test list', (tester) async {
    final session = _teacherSession();
    final fake = _FakePhaseTestService();

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.teacherTestsHw) {
            return MaterialPageRoute(
              builder: (_) => TeacherExamsView(
                session: session,
                service: fake,
                copy: TeacherExamModuleCopy.phaseTests,
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
    await tester.scrollUntilVisible(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.text(AppStrings.testsAndHw),
      ),
      80,
      scrollable: find.descendant(
        of: find.byType(Drawer),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.text(AppStrings.testsAndHw),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TeacherExamsView), findsOneWidget);
    expect(find.text(AppStrings.enterPhaseTestMarks), findsOneWidget);
    expect(find.text('First Phase'), findsOneWidget);
  });

  testWidgets('shows empty phase tests message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TeacherExamsView(
          session: _teacherSession(),
          service: _FakePhaseTestService(
            exams: const TeacherExamList(),
          ),
          copy: TeacherExamModuleCopy.phaseTests,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.noPhaseTests), findsOneWidget);
    expect(find.text(AppStrings.noExams), findsNothing);
  });

  testWidgets('shows phase test API error and retry', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TeacherExamsView(
          session: _teacherSession(),
          service: _FakePhaseTestService(
            examsError: const ApiException(
              'No teacher profile is linked to this login for this branch.',
            ),
          ),
          copy: TeacherExamModuleCopy.phaseTests,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No teacher profile is linked to this login for this branch.'),
      findsOneWidget,
    );
    expect(find.text(AppStrings.retry), findsOneWidget);
  });
}
