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
import 'package:lmssystem/models/teacher_class_attendance.dart';
import 'package:lmssystem/services/teacher_class_attendance_service.dart';
import 'package:lmssystem/views/class_attendance/teacher_class_attendance_mark_view.dart';
import 'package:lmssystem/views/class_attendance/teacher_class_attendance_view.dart';
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

Map<String, dynamic> _classesPayload() {
  return {
    'teacher': {'full_name': 'Sir Tanveer'},
    'date': '2026-09-17',
    'summary': {
      'total': 32,
      'marked': 20,
      'unmarked': 12,
      'present': 18,
      'absent': 1,
      'late': 1,
      'leave': 0,
    },
    'classes': [
      {
        'academic_session_id': 1,
        'session_name': '2026-27',
        'class_id': 4,
        'class_name': 'Grade 5',
        'sections': [
          {
            'class_section_id': 10,
            'section_name': 'A',
            'total': 20,
            'marked': 20,
            'unmarked': 0,
            'present': 18,
            'absent': 1,
            'late': 1,
            'leave': 0,
            'action': 'Update',
          },
          {
            'class_section_id': 11,
            'section_name': 'B',
            'total': 12,
            'marked': 0,
            'unmarked': 12,
            'present': 0,
            'absent': 0,
            'late': 0,
            'leave': 0,
            'action': 'Mark',
          },
        ],
      },
    ],
  };
}

Map<String, dynamic> _markPayload() {
  return {
    'date': '2026-09-17',
    'can_mark': true,
    'block_message': null,
    'already_marked': false,
    'class': {
      'academic_session_id': 1,
      'session_name': '2026-27',
      'class_id': 4,
      'class_name': 'Grade 5',
      'class_section_id': 11,
      'section_name': 'B',
    },
    'statuses': [
      {'key': 'present', 'label': 'Present'},
      {'key': 'absent', 'label': 'Absent'},
      {'key': 'late', 'label': 'Late'},
      {'key': 'leave', 'label': 'Leave'},
    ],
    'students': [
      {
        'id': 21,
        'full_name': 'Ali Khan',
        'roll_number': '05',
        'father_name': 'Asif Khan',
        'photo_url': null,
        'status': 'present',
        'already_marked': false,
        'locked': false,
      },
      {
        'id': 22,
        'full_name': 'Sara Ahmed',
        'roll_number': '12',
        'father_name': 'Imran Ahmed',
        'photo_url': null,
        'status': 'present',
        'already_marked': false,
        'locked': false,
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

class _FakeClassAttendanceService extends TeacherClassAttendanceService {
  _FakeClassAttendanceService({
    TeacherClassAttendanceClasses? classes,
    TeacherClassAttendanceMark? mark,
    this.classesError,
  })  : classes = classes ?? TeacherClassAttendanceClasses.fromJson(_classesPayload()),
        mark = mark ?? TeacherClassAttendanceMark.fromJson(_markPayload());

  TeacherClassAttendanceClasses classes;
  TeacherClassAttendanceMark mark;
  Object? classesError;
  Map<String, dynamic>? lastSave;
  String? lastMarkDate;

  @override
  Future<TeacherClassAttendanceClasses> fetchClasses(AuthSession session) async {
    if (classesError != null) throw classesError!;
    return classes;
  }

  @override
  Future<TeacherClassAttendanceMark> fetchMark(
    AuthSession session, {
    required ClassAttendanceClass classItem,
    required ClassAttendanceSection section,
    required String date,
  }) async {
    lastMarkDate = date;
    return mark;
  }

  @override
  Future<TeacherClassAttendanceSaveResult> save(
    AuthSession session, {
    required ClassAttendanceClass classItem,
    required ClassAttendanceSection section,
    required String date,
    required List<ClassAttendanceStudent> students,
  }) async {
    lastSave = {
      'class_id': classItem.classId,
      'class_section_id': section.classSectionId,
      'date': date,
      'attendance': {
        for (final student in students) '${student.id}': student.status,
      },
    };
    return const TeacherClassAttendanceSaveResult(
      saved: 2,
      message: 'Attendance saved for 2 students.',
    );
  }
}

void main() {
  test('parses class-teacher sections and today summary', () {
    final data = TeacherClassAttendanceClasses.fromJson(_classesPayload());

    expect(data.teacherName, 'Sir Tanveer');
    expect(data.summary.total, 32);
    expect(data.summary.unmarked, 12);
    expect(data.classes.single.title, 'Grade 5');
    expect(data.classes.single.sections.first.displayName, 'Section A');
    expect(data.classes.single.sections.last.actionLabel, 'Mark');
  });

  test('fetches class-teacher sections with the selected branch', () async {
    http.Request? captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode(_apiEnvelope(_classesPayload())),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final data = await TeacherClassAttendanceService(
      client: ApiClient(httpClient: client),
    ).fetchClasses(_teacherSession());

    expect(captured!.method, 'GET');
    expect(captured!.url.path, '/api/mobile/teachers/class-attendance/classes');
    expect(captured!.url.queryParameters['domain'], 'sls.localhost');
    expect(captured!.url.queryParameters['branch_id'], '1');
    expect(data.classes.single.sections, hasLength(2));
  });

  test('saves attendance for students in the class-teacher section', () async {
    http.Request? captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode(_apiEnvelope({'saved': 2}, message: 'Attendance saved for 2 students.')),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final classes = TeacherClassAttendanceClasses.fromJson(_classesPayload());
    final mark = TeacherClassAttendanceMark.fromJson(_markPayload());

    final result = await TeacherClassAttendanceService(
      client: ApiClient(httpClient: client),
    ).save(
      _teacherSession(),
      classItem: classes.classes.single,
      section: classes.classes.single.sections.last,
      date: '2026-09-17',
      students: [
        mark.students.first.copyWithStatus('absent'),
        mark.students.last,
      ],
    );

    expect(captured!.method, 'POST');
    expect(captured!.url.path, '/api/mobile/teachers/class-attendance');
    final body = jsonDecode(captured!.body) as Map<String, dynamic>;
    expect(body['domain'], 'sls.localhost');
    expect(body['branch_id'], '1');
    expect(body['class_section_id'], 11);
    expect(body['attendance']['21']['status'], 'absent');
    expect(body['attendance']['22']['status'], 'present');
    expect(result.saved, 2);
  });

  testWidgets('shows class-teacher sections on the same screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TeacherClassAttendanceView(
          session: _teacherSession(),
          service: _FakeClassAttendanceService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.myClasses), findsOneWidget);
    expect(find.text('Grade 5'), findsOneWidget);
    expect(find.text('Section A'), findsOneWidget);
    expect(find.text('Section B'), findsOneWidget);
    expect(find.text('Update'), findsOneWidget);
    expect(find.text('Mark'), findsOneWidget);
  });

  testWidgets('opens the mark sheet from a section', (tester) async {
    final fake = _FakeClassAttendanceService();

    await tester.pumpWidget(
      MaterialApp(
        home: TeacherClassAttendanceView(
          session: _teacherSession(),
          service: fake,
          clock: () => DateTime(2026, 9, 17),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('class-att-4-section-11')));
    await tester.pumpAndSettle();

    expect(find.byType(TeacherClassAttendanceMarkView), findsOneWidget);
    expect(find.text('1. Ali Khan'), findsOneWidget);
    expect(find.text('2. Sara Ahmed'), findsOneWidget);
    expect(fake.lastMarkDate, '2026-09-17');
  });

  testWidgets('saves marked statuses from the sheet', (tester) async {
    final fake = _FakeClassAttendanceService();
    final classes = TeacherClassAttendanceClasses.fromJson(_classesPayload());

    await tester.pumpWidget(
      MaterialApp(
        home: TeacherClassAttendanceMarkView(
          session: _teacherSession(),
          classItem: classes.classes.single,
          section: classes.classes.single.sections.last,
          service: fake,
          clock: () => DateTime(2026, 9, 17),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Absent').first);
    await tester.tap(find.text(AppStrings.saveAttendance));
    await tester.pump();

    expect(fake.lastSave, isNotNull);
    expect(fake.lastSave!['attendance']['21'], 'absent');
    expect(find.text('Attendance saved for 2 students.'), findsOneWidget);
  });

  testWidgets('tapping Class Attendance opens the teacher class list', (tester) async {
    final session = _teacherSession();
    final fake = _FakeClassAttendanceService();

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.teacherClassAttendance) {
            return MaterialPageRoute(
              builder: (_) => TeacherClassAttendanceView(
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
    await tester.tap(find.text(AppStrings.classAttendance));
    await tester.pumpAndSettle();

    expect(find.byType(TeacherClassAttendanceView), findsOneWidget);
    expect(find.text('Grade 5'), findsOneWidget);
  });

  testWidgets('shows empty class-teacher message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TeacherClassAttendanceView(
          session: _teacherSession(),
          service: _FakeClassAttendanceService(
            classes: const TeacherClassAttendanceClasses(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.noClassAttendance), findsOneWidget);
  });

  testWidgets('shows class attendance API error and retry', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TeacherClassAttendanceView(
          session: _teacherSession(),
          service: _FakeClassAttendanceService(
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
