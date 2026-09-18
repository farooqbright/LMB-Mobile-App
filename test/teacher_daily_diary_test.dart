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
import 'package:lmssystem/models/teacher_daily_diary.dart';
import 'package:lmssystem/services/teacher_daily_diary_service.dart';
import 'package:lmssystem/views/dashboards/teacher_dashboard_view.dart';
import 'package:lmssystem/views/diary/teacher_daily_diary_form_view.dart';
import 'package:lmssystem/views/diary/teacher_daily_diary_subjects_view.dart';
import 'package:lmssystem/views/diary/teacher_daily_diary_view.dart';

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
        'section_count': 2,
        'sections': [
          {'class_section_id': 10, 'section_name': 'A', 'subject_count': 2},
          {'class_section_id': 11, 'section_name': 'B', 'subject_count': 1},
        ],
      },
      {
        'academic_session_id': 1,
        'session_name': '2026-27',
        'class_id': 5,
        'class_name': 'Grade 6',
        'section_count': 1,
        'sections': [
          {'class_section_id': 12, 'section_name': 'A', 'subject_count': 1},
        ],
      },
    ],
  };
}

Map<String, dynamic> _subjectsPayload() {
  return {
    'class': {
      'academic_session_id': 1,
      'session_name': '2026-27',
      'class_id': 5,
      'class_name': 'Grade 6',
      'class_section_id': 12,
      'section_name': 'A',
    },
    'subjects': [
      {
        'academic_session_id': 1,
        'class_id': 5,
        'class_section_id': 12,
        'subject_id': 9,
        'subject_name': 'Mathematics',
      },
    ],
  };
}

Map<String, dynamic> _entryPayload() {
  return {
    'date': '2026-09-17',
    'target': {
      'academic_session_id': 1,
      'session_name': '2026-27',
      'class_id': 5,
      'class_name': 'Grade 6',
      'class_section_id': 12,
      'section_name': 'A',
      'subject_id': 9,
      'subject_name': 'Mathematics',
    },
    'entry': {
      'work_done': 'Fractions',
      'homework': 'Exercise 4.2',
      'remarks': null,
    },
    'sections': [
      {'id': 12, 'name': 'A'},
      {'id': 13, 'name': 'B'},
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

class _FakeDiaryService extends TeacherDailyDiaryService {
  _FakeDiaryService({
    TeacherDailyDiaryClasses? classes,
    TeacherDailyDiarySubjects? subjects,
    TeacherDailyDiaryEntry? entry,
    this.classesError,
  })  : classes = classes ?? TeacherDailyDiaryClasses.fromJson(_classesPayload()),
        subjects = subjects ?? TeacherDailyDiarySubjects.fromJson(_subjectsPayload()),
        entry = entry ?? TeacherDailyDiaryEntry.fromJson(_entryPayload());

  TeacherDailyDiaryClasses classes;
  TeacherDailyDiarySubjects subjects;
  TeacherDailyDiaryEntry entry;
  TeacherDailyDiarySaveResult saveResult = const TeacherDailyDiarySaveResult(
    saved: 1,
    message: 'Daily diary saved for 1 section.',
  );
  Object? classesError;

  Map<String, dynamic>? lastSave;
  String? lastEntryDate;

  @override
  Future<TeacherDailyDiaryClasses> fetchClasses(AuthSession session) async {
    if (classesError != null) throw classesError!;
    return classes;
  }

  @override
  Future<TeacherDailyDiarySubjects> fetchSubjects(
    AuthSession session, {
    required DiaryClass classItem,
    required DiarySection section,
  }) async {
    return subjects;
  }

  @override
  Future<TeacherDailyDiaryEntry> fetchEntry(
    AuthSession session, {
    required DiaryClass classItem,
    required DiarySection section,
    required DiarySubject subject,
    required String date,
  }) async {
    lastEntryDate = date;
    return entry;
  }

  @override
  Future<TeacherDailyDiarySaveResult> save(
    AuthSession session, {
    required DiaryClass classItem,
    required DiarySection section,
    required DiarySubject subject,
    required String date,
    required List<int> sectionIds,
    String? workDone,
    String? homework,
    String? remarks,
  }) async {
    lastSave = {
      'class_id': classItem.classId,
      'class_section_id': section.classSectionId,
      'subject_id': subject.subjectId,
      'diary_date': date,
      'class_section_ids': sectionIds,
      'work_done': workDone,
      'homework': homework,
      'remarks': remarks,
    };
    return saveResult;
  }
}

void main() {
  test('parses teaching classes and sections from the diary payload', () {
    final data = TeacherDailyDiaryClasses.fromJson(_classesPayload());

    expect(data.teacherName, 'Sir Tanveer');
    expect(data.classes, hasLength(2));
    expect(data.classes.first.title, 'Grade 5');
    expect(data.classes.first.footerLabel, '2 sections');
    expect(data.classes.last.footerLabel, 'A');
    expect(data.classes.first.sections.map((section) => section.displayName).toList(), ['Section A', 'Section B']);
  });

  test('parses timetable subjects and an existing diary entry', () {
    final subjects = TeacherDailyDiarySubjects.fromJson(_subjectsPayload());
    final entry = TeacherDailyDiaryEntry.fromJson(_entryPayload());

    expect(subjects.subjects.single.title, 'Mathematics');
    expect(entry.heading, 'Mathematics — Daily Diary');
    expect(entry.workDone, 'Fractions');
    expect(entry.sections.map((section) => section.title).toList(), ['A', 'B']);
    expect(displayDiaryDate('2026-09-17'), '17/09/2026');
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

    final data = await TeacherDailyDiaryService(
      client: ApiClient(httpClient: client),
    ).fetchClasses(_teacherSession());

    expect(captured, isNotNull);
    expect(captured!.method, 'GET');
    expect(captured!.url.path, '/api/mobile/teachers/daily-diary/classes');
    expect(captured!.url.queryParameters['domain'], 'sls.localhost');
    expect(captured!.url.queryParameters['branch_id'], '1');
    expect(captured!.headers['Authorization'], 'Bearer teacher.token');
    expect(data.classes, hasLength(2));
  });

  test('requires a selected branch before loading diary classes', () async {
    expect(
      () => TeacherDailyDiaryService().fetchClasses(_teacherSession(branchId: null)),
      throwsA(isA<ApiException>()),
    );
  });

  test('saves a subject diary for the taught sections', () async {
    http.Request? captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode(_apiEnvelope({'saved': 2}, message: 'Daily diary saved for 2 sections.')),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final classes = TeacherDailyDiaryClasses.fromJson(_classesPayload());
    final grade6 = classes.classes.last;
    final subjects = TeacherDailyDiarySubjects.fromJson(_subjectsPayload());

    final result = await TeacherDailyDiaryService(
      client: ApiClient(httpClient: client),
    ).save(
      _teacherSession(),
      classItem: grade6,
      section: grade6.sections.first,
      subject: subjects.subjects.first,
      date: '2026-09-17',
      sectionIds: const [12, 13],
      workDone: 'Fractions',
      homework: 'Exercise 4.2',
      remarks: '  ',
    );

    expect(captured, isNotNull);
    expect(captured!.method, 'POST');
    expect(captured!.url.path, '/api/mobile/teachers/daily-diary');
    final body = jsonDecode(captured!.body) as Map<String, dynamic>;
    expect(body['domain'], 'sls.localhost');
    expect(body['branch_id'], '1');
    expect(body['academic_session_id'], 1);
    expect(body['class_id'], 5);
    expect(body['class_section_id'], 12);
    expect(body['subject_id'], 9);
    expect(body['diary_date'], '2026-09-17');
    expect(body['class_section_ids'], [12, 13]);
    expect(body['work_done'], 'Fractions');
    expect(body['homework'], 'Exercise 4.2');
    expect(body['remarks'], isNull);
    expect(result.saved, 2);
    expect(result.message, 'Daily diary saved for 2 sections.');
  });

  testWidgets('shows teaching classes with sections on the same screen', (tester) async {
    final fake = _FakeDiaryService();

    await tester.pumpWidget(
      MaterialApp(
        home: TeacherDailyDiaryView(
          session: _teacherSession(),
          service: fake,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.myClasses), findsOneWidget);
    expect(find.text('Grade 5'), findsOneWidget);
    expect(find.text('Grade 6'), findsOneWidget);
    expect(find.text('2 sections'), findsNothing);
    expect(find.text('Section A'), findsWidgets);
    expect(find.text('Section B'), findsOneWidget);
    expect(find.text('2 subjects'), findsNothing);
    expect(find.text('1 subject'), findsNothing);
    expect(find.byIcon(Icons.school_rounded), findsWidgets);
    expect(find.byIcon(Icons.groups_rounded), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('diary-class-5-section-12')));
    await tester.pumpAndSettle();

    expect(find.byType(TeacherDailyDiarySubjectsView), findsOneWidget);
    expect(find.text('Mathematics'), findsOneWidget);
    expect(find.text(AppStrings.addDiary), findsOneWidget);
  });

  testWidgets('opens subjects from a section without leaving the class list first', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TeacherDailyDiaryView(
          session: _teacherSession(),
          service: _FakeDiaryService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('diary-class-4-section-11')));
    await tester.pumpAndSettle();

    expect(find.byType(TeacherDailyDiarySubjectsView), findsOneWidget);
    expect(find.text('Grade 5 — B'), findsWidgets);
  });

  testWidgets('opens the subject diary form and saves taught sections', (tester) async {
    final fake = _FakeDiaryService();
    final classes = TeacherDailyDiaryClasses.fromJson(_classesPayload());
    final grade6 = classes.classes.last;
    final subjects = TeacherDailyDiarySubjects.fromJson(_subjectsPayload());

    await tester.pumpWidget(
      MaterialApp(
        home: TeacherDailyDiaryFormView(
          session: _teacherSession(),
          classItem: grade6,
          section: grade6.sections.first,
          subject: subjects.subjects.first,
          service: fake,
          clock: () => DateTime(2026, 9, 17),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mathematics — Daily Diary'), findsWidgets);
    expect(find.text('Fractions'), findsOneWidget);
    expect(find.text('Section A'), findsOneWidget);
    expect(find.text('Section B'), findsOneWidget);
    expect(fake.lastEntryDate, '2026-09-17');

    await tester.enterText(find.byType(TextField).first, 'Decimals');
    await tester.tap(find.text('Section B'));
    await tester.tap(find.text(AppStrings.saveDiary));
    await tester.pump();

    expect(fake.lastSave, isNotNull);
    expect(fake.lastSave!['work_done'], 'Decimals');
    expect(fake.lastSave!['class_section_ids'], [12, 13]);
    expect(find.text('Daily diary saved for 1 section.'), findsOneWidget);
  });

  testWidgets('tapping Daily Diary opens the teacher diary screen', (tester) async {
    final session = _teacherSession();
    final fake = _FakeDiaryService();

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.teacherDailyDiary) {
            return MaterialPageRoute(
              builder: (_) => TeacherDailyDiaryView(
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
    await tester.tap(find.text(AppStrings.dailyDiary));
    await tester.pumpAndSettle();

    expect(find.byType(TeacherDailyDiaryView), findsOneWidget);
    expect(find.text('Grade 5'), findsOneWidget);
  });

  testWidgets('shows empty diary classes message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TeacherDailyDiaryView(
          session: _teacherSession(),
          service: _FakeDiaryService(
            classes: const TeacherDailyDiaryClasses(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.noDiaryClasses), findsOneWidget);
    expect(find.text(AppStrings.noDiaryClassesHint), findsOneWidget);
  });

  testWidgets('shows diary API error and retry', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TeacherDailyDiaryView(
          session: _teacherSession(),
          service: _FakeDiaryService(
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
