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
import 'package:lmssystem/models/teacher_assessment.dart';
import 'package:lmssystem/services/teacher_assessment_service.dart';
import 'package:lmssystem/views/dashboards/teacher_dashboard_view.dart';
import 'package:lmssystem/views/tests_hw/teacher_tests_hw_form_view.dart';
import 'package:lmssystem/views/tests_hw/teacher_tests_hw_marks_view.dart';
import 'package:lmssystem/views/tests_hw/teacher_tests_hw_section_view.dart';
import 'package:lmssystem/views/tests_hw/teacher_tests_hw_view.dart';

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

Map<String, dynamic> _classesPayload() {
  return {
    'teacher': {'full_name': 'Sir Tanveer'},
    'classes': [
      {
        'academic_session_id': 1,
        'session_name': '2026-27',
        'class_id': 4,
        'class_name': 'Grade 5',
        'sections': [
          {'class_section_id': 10, 'section_name': 'A'},
          {'class_section_id': 11, 'section_name': 'B'},
        ],
      },
    ],
  };
}

Map<String, dynamic> _sectionPayload() {
  return {
    'class': {
      'academic_session_id': 1,
      'session_name': '2026-27',
      'class_id': 4,
      'class_name': 'Grade 5',
      'class_section_id': 10,
      'section_name': 'A',
    },
    'subjects': [
      {'subject_id': 9, 'subject_name': 'Mathematics'},
    ],
    'assessments': [
      {
        'id': 15,
        'type': 'test',
        'type_label': 'Test',
        'title': 'Chapter 3 Test',
        'assessment_date': '2026-09-17',
        'total_marks': 20,
        'marks_count': 2,
        'subject_id': 9,
        'subject_name': 'Mathematics',
      },
    ],
  };
}

Map<String, dynamic> _assessmentPayload() {
  return {
    'id': 16,
    'type': 'assignment',
    'type_label': 'Assignment',
    'title': 'Exercise 4.2',
    'assessment_date': '2026-09-17',
    'due_date': '2026-09-20',
    'total_marks': 10,
    'subject_id': 9,
    'subject_name': 'Mathematics',
    'class_id': 4,
    'class_section_id': 10,
    'academic_session_id': 1,
  };
}

Map<String, dynamic> _marksPayload() {
  return {
    'assessment': _assessmentPayload(),
    'students': [
      {
        'id': 21,
        'full_name': 'Ali Khan',
        'roll_number': '05',
        'marks_obtained': 8,
        'is_absent': false,
      },
      {
        'id': 22,
        'full_name': 'Sara Ahmed',
        'roll_number': '12',
        'marks_obtained': null,
        'is_absent': false,
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

class _FakeAssessmentService extends TeacherAssessmentService {
  _FakeAssessmentService({
    TeacherAssessmentClasses? classes,
    TeacherAssessmentSectionData? section,
    TeacherAssessmentMarks? marks,
    this.classesError,
  })  : classes = classes ?? TeacherAssessmentClasses.fromJson(_classesPayload()),
        section = section ?? TeacherAssessmentSectionData.fromJson(_sectionPayload()),
        marks = marks ?? TeacherAssessmentMarks.fromJson(_marksPayload());

  TeacherAssessmentClasses classes;
  TeacherAssessmentSectionData section;
  TeacherAssessmentMarks marks;
  Object? classesError;
  Map<String, dynamic>? lastSave;
  Map<String, dynamic>? lastMarksSave;

  @override
  Future<TeacherAssessmentClasses> fetchClasses(AuthSession session) async {
    if (classesError != null) throw classesError!;
    return classes;
  }

  @override
  Future<TeacherAssessmentSectionData> fetchSection(
    AuthSession session, {
    required AssessmentClass classItem,
    required AssessmentSection section,
  }) async {
    return this.section;
  }

  @override
  Future<TeacherAssessmentSaveResult> save(
    AuthSession session, {
    required AssessmentClass classItem,
    required AssessmentSection section,
    required AssessmentSubject subject,
    TeacherAssessment? existing,
    required String type,
    required String title,
    String? description,
    required String assessmentDate,
    String? dueDate,
    int? totalMarks,
    String? remarks,
  }) async {
    lastSave = {
      'class_id': classItem.classId,
      'class_section_id': section.classSectionId,
      'subject_id': subject.subjectId,
      'type': type,
      'title': title,
      'assessment_date': assessmentDate,
      'due_date': dueDate,
      'total_marks': totalMarks,
    };
    return TeacherAssessmentSaveResult(
      message: 'Record saved. Enter student marks below.',
      assessment: TeacherAssessment.fromJson(_assessmentPayload()),
    );
  }

  @override
  Future<TeacherAssessmentMarks> fetchMarks(
    AuthSession session, {
    required int assessmentId,
  }) async {
    return marks;
  }

  @override
  Future<TeacherAssessmentSaveResult> saveMarks(
    AuthSession session, {
    required int assessmentId,
    required List<Map<String, dynamic>> entries,
  }) async {
    lastMarksSave = {
      'assessment_id': assessmentId,
      'entries': entries,
    };
    return const TeacherAssessmentSaveResult(
      saved: 2,
      message: 'Marks saved for 2 students.',
    );
  }
}

void main() {
  test('parses teaching classes and nested sections', () {
    final data = TeacherAssessmentClasses.fromJson(_classesPayload());

    expect(data.teacherName, 'Sir Tanveer');
    expect(data.classes.single.title, 'Grade 5');
    expect(
      data.classes.single.sections.map((section) => section.displayName).toList(),
      ['Section A', 'Section B'],
    );
  });

  test('parses subjects and saved assessments', () {
    final data = TeacherAssessmentSectionData.fromJson(_sectionPayload());

    expect(data.subjects.single.title, 'Mathematics');
    expect(data.assessments.single.displayTitle, 'Chapter 3 Test');
    expect(data.assessments.single.displayType, 'Test');
    expect(displayAssessmentDate('2026-09-17'), '17 Sep 2026');
  });

  test('fetches classes with the selected branch', () async {
    http.Request? captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode(_apiEnvelope(_classesPayload())),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final data = await TeacherAssessmentService(
      client: ApiClient(httpClient: client),
    ).fetchClasses(_teacherSession());

    expect(captured, isNotNull);
    expect(captured!.method, 'GET');
    expect(captured!.url.path, '/api/mobile/teachers/assessments/classes');
    expect(captured!.url.queryParameters['domain'], 'sls.localhost');
    expect(captured!.url.queryParameters['branch_id'], '1');
    expect(captured!.headers['Authorization'], 'Bearer teacher.token');
    expect(data.classes, hasLength(1));
  });

  test('requires a selected branch before loading tests and homework', () async {
    expect(
      () => TeacherAssessmentService().fetchClasses(_teacherSession(branchId: null)),
      throwsA(isA<ApiException>()),
    );
  });

  test('saves a homework assignment for a taught subject', () async {
    http.Request? captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode(_apiEnvelope(
          {'assessment': _assessmentPayload()},
          message: 'Record saved. Enter student marks below.',
        )),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final classes = TeacherAssessmentClasses.fromJson(_classesPayload());
    final classItem = classes.classes.single;
    final result = await TeacherAssessmentService(
      client: ApiClient(httpClient: client),
    ).save(
      _teacherSession(),
      classItem: classItem,
      section: classItem.sections.first,
      subject: const AssessmentSubject(subjectId: 9, subjectName: 'Mathematics'),
      type: 'assignment',
      title: 'Exercise 4.2',
      assessmentDate: '2026-09-17',
      dueDate: '2026-09-20',
      totalMarks: 10,
    );

    expect(captured, isNotNull);
    expect(captured!.method, 'POST');
    expect(captured!.url.path, '/api/mobile/teachers/assessments');
    final body = jsonDecode(captured!.body) as Map<String, dynamic>;
    expect(body['domain'], 'sls.localhost');
    expect(body['branch_id'], '1');
    expect(body['class_id'], 4);
    expect(body['class_section_id'], 10);
    expect(body['subject_id'], 9);
    expect(body['type'], 'assignment');
    expect(body['title'], 'Exercise 4.2');
    expect(body['due_date'], '2026-09-20');
    expect(result.assessment?.displayTitle, 'Exercise 4.2');
  });

  testWidgets('shows classes and opens nested sections', (tester) async {
    final fake = _FakeAssessmentService();

    await tester.pumpWidget(
      MaterialApp(
        home: TeacherTestsHwView(
          session: _teacherSession(),
          service: fake,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Grade 5'), findsOneWidget);
    expect(find.text('Section A'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tests-hw-class-4-section-10')));
    await tester.pumpAndSettle();

    expect(find.byType(TeacherTestsHwSectionView), findsOneWidget);
    expect(find.text('Mathematics'), findsWidgets);
    expect(find.text(AppStrings.addTest), findsOneWidget);
    expect(find.text(AppStrings.addHw), findsOneWidget);
    expect(find.text('Chapter 3 Test'), findsOneWidget);
  });

  testWidgets('saves a test from the form', (tester) async {
    final fake = _FakeAssessmentService();
    final classes = TeacherAssessmentClasses.fromJson(_classesPayload());

    await tester.pumpWidget(
      MaterialApp(
        home: TeacherTestsHwFormView(
          session: _teacherSession(),
          classItem: classes.classes.single,
          section: classes.classes.single.sections.first,
          subject: const AssessmentSubject(subjectId: 9, subjectName: 'Mathematics'),
          type: 'test',
          service: fake,
          clock: () => DateTime(2026, 9, 17),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Chapter 3 Test');
    await tester.tap(find.text(AppStrings.save));
    await tester.pump();

    expect(fake.lastSave, isNotNull);
    expect(fake.lastSave!['type'], 'test');
    expect(fake.lastSave!['title'], 'Chapter 3 Test');
    expect(fake.lastSave!['assessment_date'], '2026-09-17');
  });

  testWidgets('saves student marks from the sheet', (tester) async {
    final fake = _FakeAssessmentService();

    await tester.pumpWidget(
      MaterialApp(
        home: TeacherTestsHwMarksView(
          session: _teacherSession(),
          assessment: TeacherAssessment.fromJson(_assessmentPayload()),
          service: fake,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.absentShort).last);
    await tester.tap(find.text(AppStrings.saveMarks));
    await tester.pump();

    expect(fake.lastMarksSave, isNotNull);
    expect(fake.lastMarksSave!['entries'].last['is_absent'], isTrue);
    expect(find.text('Marks saved for 2 students.'), findsOneWidget);
  });

  testWidgets('tapping Phase Tests opens the teacher class list', (tester) async {
    final session = _teacherSession();
    final fake = _FakeAssessmentService();

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.teacherTestsHw) {
            return MaterialPageRoute(
              builder: (_) => TeacherTestsHwView(
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

    expect(find.byType(TeacherTestsHwView), findsOneWidget);
    expect(find.text('Grade 5'), findsOneWidget);
  });

  testWidgets('shows empty tests and homework message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TeacherTestsHwView(
          session: _teacherSession(),
          service: _FakeAssessmentService(
            classes: const TeacherAssessmentClasses(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.noTestsHwClasses), findsOneWidget);
  });

  testWidgets('shows tests and homework API error and retry', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TeacherTestsHwView(
          session: _teacherSession(),
          service: _FakeAssessmentService(
            classesError: const ApiException(
              'No teacher profile is linked to this login for this branch.',
            ),
          ),
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
