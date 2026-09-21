import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lmssystem/core/constants/app_strings.dart';
import 'package:lmssystem/core/network/api_exception.dart';
import 'package:lmssystem/models/auth_session.dart';
import 'package:lmssystem/models/teacher_attendance.dart';
import 'package:lmssystem/parent/controllers/parent_special_remarks_controller.dart';
import 'package:lmssystem/parent/models/parent_special_remarks.dart';
import 'package:lmssystem/parent/screens/parent_special_remarks_view.dart';
import 'package:lmssystem/parent/services/parent_special_remarks_service.dart';

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

class _FakeRemarksService extends ParentSpecialRemarksService {
  _FakeRemarksService(this.pages, {this.error});

  final List<ParentSpecialRemarksData> pages;
  final Object? error;
  ParentSpecialRemarksQuery? lastQuery;
  var fetches = 0;

  @override
  Future<ParentSpecialRemarksData> fetch(
    AuthSession session, {
    ParentSpecialRemarksQuery query = const ParentSpecialRemarksQuery(),
  }) async {
    fetches += 1;
    lastQuery = query;
    if (error != null) throw error!;
    final index = (query.page - 1).clamp(0, pages.length - 1);
    return pages[index];
  }
}

ParentSpecialRemarksData _sampleData({
  int page = 1,
  int lastPage = 1,
  bool isNew = true,
  String remarks = 'Please complete pending homework.',
}) {
  return ParentSpecialRemarksData.fromJson({
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
    'remarks_count': lastPage > 1 ? 2 : 1,
    'new_count': isNew ? 1 : 0,
    'remarks': [
      {
        'id': page,
        'remark_date': '2026-09-18',
        'date_label': page == 1 ? '18 Sep 2026' : '17 Sep 2026',
        'weekday': page == 1 ? 'Friday' : 'Thursday',
        'remarks': remarks,
        'teacher_name': 'Sir Tanveer',
        'is_new': isNew && page == 1,
      },
    ],
  }, metaJson: {
    'current_page': page,
    'last_page': lastPage,
    'per_page': 25,
    'total': lastPage > 1 ? 2 : 1,
  });
}

void main() {
  test('parses special remarks and new flags', () {
    final data = _sampleData();

    expect(data.studentName, 'Ahmed Ali');
    expect(data.classLabel, 'Class 5 - A');
    expect(data.remarks, hasLength(1));
    expect(data.remarks.first.teacherName, 'Sir Tanveer');
    expect(data.remarks.first.isNew, isTrue);
    expect(data.hasMore, isFalse);
  });

  test('defaults the remarks filter to today', () {
    final controller = ParentSpecialRemarksController(
      session: _parentSession(),
      clock: () => DateTime(2026, 9, 18),
    );

    expect(controller.period, ParentRemarksPeriod.today);
    expect(isoAttendanceDate(controller.selectedDate), '2026-09-18');
    expect(controller.queryFor().period, 'today');
  });

  test('all filter sends all', () async {
    final fake = _FakeRemarksService([_sampleData()]);
    final controller = ParentSpecialRemarksController(
      session: _parentSession(),
      service: fake,
      clock: () => DateTime(2026, 9, 18),
    );

    await controller.selectPeriod(ParentRemarksPeriod.all);

    expect(fake.fetches, 1);
    expect(fake.lastQuery?.period, 'all');
    expect(controller.rangeLabel, 'All remarks');
  });

  testWidgets('shows selected student special remarks for today', (tester) async {
    final fake = _FakeRemarksService([_sampleData()]);

    await tester.pumpWidget(
      MaterialApp(
        home: ParentSpecialRemarksView(
          session: _parentSession(),
          service: fake,
          clock: () => DateTime(2026, 9, 18),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.specialRemarks), findsWidgets);
    expect(find.text('Ahmed Ali'), findsOneWidget);
    expect(find.text(AppStrings.attendanceToday), findsOneWidget);
    expect(find.text(AppStrings.lastWeek), findsOneWidget);
    expect(find.text(AppStrings.allRemarks), findsOneWidget);
    expect(find.text('Please complete pending homework.'), findsOneWidget);
    expect(find.text('Sir Tanveer'), findsOneWidget);
    expect(find.text(AppStrings.newRemark), findsOneWidget);
  });

  testWidgets('loads more remarks when another page exists', (tester) async {
    final fake = _FakeRemarksService([
      _sampleData(page: 1, lastPage: 2),
      _sampleData(
        page: 2,
        lastPage: 2,
        isNew: false,
        remarks: 'Keep up the good work.',
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: ParentSpecialRemarksView(
          session: _parentSession(),
          service: fake,
          clock: () => DateTime(2026, 9, 18),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.loadMore), findsOneWidget);
    await tester.tap(find.text(AppStrings.loadMore));
    await tester.pumpAndSettle();

    expect(fake.fetches, 2);
    expect(fake.lastQuery?.page, 2);
    expect(find.text('Please complete pending homework.'), findsOneWidget);
    expect(find.text('Keep up the good work.'), findsOneWidget);
  });

  testWidgets('shows API error and retry', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ParentSpecialRemarksView(
          session: _parentSession(),
          service: _FakeRemarksService(
            [_sampleData()],
            error: const ApiException('Student not found for this parent account.'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Student not found for this parent account.'),
      findsOneWidget,
    );
    expect(find.text(AppStrings.retry), findsOneWidget);
  });
}
