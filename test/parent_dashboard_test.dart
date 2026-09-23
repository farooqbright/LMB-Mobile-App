import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lmssystem/app/routes.dart';
import 'package:lmssystem/core/constants/app_strings.dart';
import 'package:lmssystem/core/network/api_exception.dart';
import 'package:lmssystem/models/auth_session.dart';
import 'package:lmssystem/parent/models/parent_attendance.dart';
import 'package:lmssystem/parent/screens/parent_attendance_view.dart';
import 'package:lmssystem/parent/screens/parent_daily_diary_view.dart';
import 'package:lmssystem/parent/screens/parent_dashboard_view.dart';
import 'package:lmssystem/parent/screens/parent_fee_vouchers_view.dart';
import 'package:lmssystem/parent/screens/parent_special_remarks_view.dart';
import 'package:lmssystem/parent/screens/parent_timetable_view.dart';
import 'package:lmssystem/parent/services/parent_attendance_service.dart';
import 'package:lmssystem/parent/services/parent_daily_diary_service.dart';
import 'package:lmssystem/parent/services/parent_fee_voucher_service.dart';
import 'package:lmssystem/parent/services/parent_special_remarks_service.dart';
import 'package:lmssystem/parent/services/parent_timetable_service.dart';
import 'package:lmssystem/parent/models/parent_daily_diary.dart';
import 'package:lmssystem/parent/models/parent_fee_vouchers.dart';
import 'package:lmssystem/parent/models/parent_special_remarks.dart';
import 'package:lmssystem/parent/models/parent_timetable.dart';
import 'package:lmssystem/parent/widgets/parent_student_photo.dart';

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

class _FakeAttendanceService extends ParentAttendanceService {
  _FakeAttendanceService(this.data, {this.error, this.delay = Duration.zero});

  final ParentAttendanceData data;
  final Object? error;
  final Duration delay;
  var fetches = 0;

  @override
  Future<ParentAttendanceData> fetch(
    AuthSession session, {
    ParentAttendanceQuery query = const ParentAttendanceQuery(),
  }) async {
    fetches += 1;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (error != null) throw error!;
    return data;
  }
}

class _FakeDiaryService extends ParentDailyDiaryService {
  @override
  Future<ParentDailyDiaryData> fetch(
    AuthSession session, {
    ParentDailyDiaryQuery query = const ParentDailyDiaryQuery(),
  }) async {
    return ParentDailyDiaryData.fromJson({
      'student': {
        'student_id': 11,
        'full_name': 'Ahmed Ali',
        'class_name': 'Class 5',
        'section_name': 'A',
        'branch_name': 'Main Campus',
      },
      'period': 'today',
      'range_label': 'Today · 18 Sep 2026',
      'has_enrollment': true,
      'days_count': 1,
      'subjects_count': 1,
      'days': [
        {
          'date': '2026-09-18',
          'date_label': '18 Sep 2026',
          'weekday': 'Friday',
          'entries': [
            {
              'id': 1,
              'subject_name': 'Mathematics',
              'work_done': 'Fractions',
              'homework': 'Exercise 4.2',
            },
          ],
        },
      ],
    });
  }
}

class _FakeRemarksService extends ParentSpecialRemarksService {
  @override
  Future<ParentSpecialRemarksData> fetch(
    AuthSession session, {
    ParentSpecialRemarksQuery query = const ParentSpecialRemarksQuery(),
  }) async {
    return ParentSpecialRemarksData.fromJson({
      'student': {
        'student_id': 11,
        'full_name': 'Ahmed Ali',
        'class_name': 'Class 5',
        'section_name': 'A',
        'branch_name': 'Main Campus',
      },
      'period': 'today',
      'range_label': 'Today · 18 Sep 2026',
      'has_enrollment': true,
      'remarks_count': 1,
      'new_count': 1,
      'remarks': [
        {
          'id': 1,
          'remark_date': '2026-09-18',
          'date_label': '18 Sep 2026',
          'weekday': 'Friday',
          'remarks': 'Please complete pending homework.',
          'teacher_name': 'Sir Tanveer',
          'is_new': true,
        },
      ],
    });
  }
}

class _FakeFeeVoucherService extends ParentFeeVoucherService {
  @override
  Future<ParentFeeVoucherData> fetch(
    AuthSession session, {
    ParentFeeVoucherQuery query = const ParentFeeVoucherQuery(),
  }) async {
    return ParentFeeVoucherData.fromJson({
      'student': {
        'student_id': 11,
        'full_name': 'Ahmed Ali',
        'roll_number': '05',
        'class_name': 'Class 5',
        'section_name': 'A',
        'branch_name': 'Main Campus',
        'session_name': '2026-27',
      },
      'has_enrollment': true,
      'counts': {'unpaid': 1, 'partial': 0, 'invoices': 0, 'ledger': 0},
      'unpaid': [
        {
          'id': 21,
          'voucher_no': 'FV-1001',
          'session_name': '2026-27',
          'month': 'September',
          'due_date_label': '10 Sep 2026',
          'net_payable': 12500,
          'payment_status': 'unpaid',
          'status_label': 'Unpaid',
        },
      ],
      'partial': [],
      'invoices': [],
      'ledger': {
        'total_debit': 0,
        'total_credit': 0,
        'net_balance': 0,
        'entries': [],
      },
    });
  }
}

class _FakeParentTimetableService extends ParentTimetableService {
  @override
  Future<ParentTimetableData> fetch(AuthSession session) async {
    return ParentTimetableData.fromJson({
      'student': {
        'student_id': 11,
        'full_name': 'Ahmed Ali',
        'class_name': 'Class 5',
        'section_name': 'A',
        'branch_name': 'Main Campus',
      },
      'has_enrollment': true,
      'schedule': {
        'timetable_id': 3,
        'name': 'Winter timetable',
        'label': 'Class 5 — A',
        'working_days': [
          {'day': 1, 'label': 'Monday'},
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
                    'subject_name': 'Mathematics',
                    'teacher_name': 'Sir Ali',
                  },
                ],
              },
            ],
          },
        ],
      },
    });
  }
}

ParentAttendanceData _presentToday() {
  return ParentAttendanceData.fromJson({
    'student': {
      'student_id': 11,
      'full_name': 'Ahmed Ali',
      'class_name': 'Class 5',
      'section_name': 'A',
    },
    'month_label': 'September 2026',
    'summary': {
      'today': {'status': 'present', 'status_label': 'Present'},
      'month': {'total': 10, 'present': 8, 'absent': 1, 'late': 1, 'leave': 0},
    },
    'last_30_days': [
      {
        'id': 1,
        'date': '2026-09-18',
        'date_label': '18 Sep 2026',
        'status': 'present',
        'status_label': 'Present',
      },
    ],
    'records': [
      {
        'id': 1,
        'date': '2026-09-18',
        'date_label': '18 Sep 2026',
        'status': 'present',
        'status_label': 'Present',
      },
    ],
  });
}

void main() {
  testWidgets('parent dashboard shows student attendance status', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ParentDashboardView(
          session: _parentSession(),
          attendanceService: _FakeAttendanceService(_presentToday()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.todaysAttendance), findsOneWidget);
    expect(find.text('Present'), findsWidgets);
    expect(find.text(AppStrings.thisMonth), findsOneWidget);
    expect(find.text(AppStrings.specialRemarks), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
  });

  testWidgets('pulling down the parent dashboard reloads attendance', (tester) async {
    final fake = _FakeAttendanceService(
      _presentToday(),
      delay: const Duration(milliseconds: 400),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ParentDashboardView(
          session: _parentSession(),
          attendanceService: fake,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(fake.fetches, 1);

    await tester.fling(find.byType(CustomScrollView), const Offset(0, 400), 1200);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('pull-refresh-loading')), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pull-refresh-loading')), findsNothing);

    expect(fake.fetches, 2);
  });

  testWidgets('parent dashboard retries attendance after an error', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ParentDashboardView(
          session: _parentSession(),
          attendanceService: _FakeAttendanceService(
            const ParentAttendanceData(),
            error: const ApiException('Unable to load attendance.'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to load attendance.'), findsOneWidget);
    expect(find.text(AppStrings.retry), findsOneWidget);
  });

  testWidgets('tapping attendance status opens student attendance', (tester) async {
    final session = _parentSession();
    final fake = _FakeAttendanceService(_presentToday());

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.parentAttendance) {
            return MaterialPageRoute(
              builder: (_) => ParentAttendanceView(
                session: session,
                service: fake,
              ),
              settings: settings,
            );
          }
          return AppRoutes.onGenerateRoute(settings);
        },
        home: ParentDashboardView(
          session: session,
          attendanceService: fake,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.todaysAttendance));
    await tester.pumpAndSettle();

    expect(find.byType(ParentAttendanceView), findsOneWidget);
    expect(find.text('18 Sep 2026'), findsOneWidget);
  });

  testWidgets('drawer shows student identity and parent links', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: ParentDashboardView(
          session: _parentSession(),
          attendanceService: _FakeAttendanceService(_presentToday()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Ahmed Ali'), findsWidgets);
    expect(find.text('Class 5 - A'), findsOneWidget);
    expect(find.byType(ParentStudentPhoto), findsOneWidget);
    expect(find.text(AppStrings.attendance), findsWidgets);
    expect(find.text(AppStrings.dailyDiary), findsWidgets);
    expect(find.text(AppStrings.specialRemarks), findsWidgets);
    expect(find.text(AppStrings.feeVouchers), findsWidgets);
    expect(find.text(AppStrings.timeTable), findsWidgets);
    await tester.scrollUntilVisible(
      find.text(AppStrings.datesheet),
      80,
      scrollable: find.descendant(
        of: find.byType(Drawer),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text(AppStrings.results), findsWidgets);
    expect(find.text(AppStrings.datesheet), findsWidgets);
  });

  testWidgets('tapping Daily Diary opens student diary', (tester) async {
    final session = _parentSession();

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.parentDailyDiary) {
            return MaterialPageRoute(
              builder: (_) => ParentDailyDiaryView(
                session: session,
                service: _FakeDiaryService(),
                clock: () => DateTime(2026, 9, 18),
              ),
              settings: settings,
            );
          }
          return AppRoutes.onGenerateRoute(settings);
        },
        home: ParentDashboardView(
          session: session,
          attendanceService: _FakeAttendanceService(_presentToday()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.text(AppStrings.dailyDiary),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ParentDailyDiaryView), findsOneWidget);
    expect(find.text(AppStrings.attendanceToday), findsOneWidget);
    expect(find.text(AppStrings.lastWeek), findsOneWidget);
    expect(find.text('Mathematics'), findsOneWidget);
  });

  testWidgets('tapping Special Remarks opens student remarks', (tester) async {
    final session = _parentSession();

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.parentSpecialRemarks) {
            return MaterialPageRoute(
              builder: (_) => ParentSpecialRemarksView(
                session: session,
                service: _FakeRemarksService(),
                clock: () => DateTime(2026, 9, 18),
              ),
              settings: settings,
            );
          }
          return AppRoutes.onGenerateRoute(settings);
        },
        home: ParentDashboardView(
          session: session,
          attendanceService: _FakeAttendanceService(_presentToday()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.text(AppStrings.specialRemarks),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ParentSpecialRemarksView), findsOneWidget);
    expect(find.text('Please complete pending homework.'), findsOneWidget);
    expect(find.text(AppStrings.allRemarks), findsOneWidget);
  });

  testWidgets('tapping Time Table opens student timetable', (tester) async {
    final session = _parentSession();

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.parentTimetable) {
            return MaterialPageRoute(
              builder: (_) => ParentTimetableView(
                session: session,
                service: _FakeParentTimetableService(),
                clock: () => DateTime(2026, 9, 14, 8),
              ),
              settings: settings,
            );
          }
          return AppRoutes.onGenerateRoute(settings);
        },
        home: ParentDashboardView(
          session: session,
          attendanceService: _FakeAttendanceService(_presentToday()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.text(AppStrings.timeTable),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ParentTimetableView), findsOneWidget);
    expect(find.text('Mathematics'), findsOneWidget);
    expect(find.text('Sir Ali'), findsOneWidget);
  });

  testWidgets('tapping Fee Vouchers opens student fee vouchers', (tester) async {
    final session = _parentSession();

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.parentFeeVouchers) {
            return MaterialPageRoute(
              builder: (_) => ParentFeeVouchersView(
                session: session,
                service: _FakeFeeVoucherService(),
              ),
              settings: settings,
            );
          }
          return AppRoutes.onGenerateRoute(settings);
        },
        home: ParentDashboardView(
          session: session,
          attendanceService: _FakeAttendanceService(_presentToday()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.text(AppStrings.feeVouchers),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ParentFeeVouchersView), findsOneWidget);
    expect(find.text(AppStrings.feeVouchersUnpaid), findsOneWidget);
    expect(find.text('FV-1001'), findsOneWidget);
  });
}
