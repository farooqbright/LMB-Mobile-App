import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lmssystem/app/routes.dart';
import 'package:lmssystem/controllers/teacher_attendance_controller.dart';
import 'package:lmssystem/core/constants/app_strings.dart';
import 'package:lmssystem/core/network/api_client.dart';
import 'package:lmssystem/core/network/api_exception.dart';
import 'package:lmssystem/models/auth_session.dart';
import 'package:lmssystem/models/teacher_attendance.dart';
import 'package:lmssystem/services/device_location_service.dart';
import 'package:lmssystem/services/teacher_attendance_service.dart';
import 'package:lmssystem/views/attendance/teacher_attendance_view.dart';
import 'package:lmssystem/views/dashboards/teacher_dashboard_view.dart';

AuthSession _teacherSession() {
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
      'branch_id': 1,
      'branch_name': 'Avicenna Campus',
      'full_name': 'Sir Tanveer',
    },
  });
}

Map<String, dynamic> _samplePayload() {
  return {
    'teacher': {'full_name': 'Sir Tanveer'},
    'branch': {'branch_id': 1, 'branch_name': 'Avicenna Campus'},
    'person_type': 'teacher',
    'month_label': 'September 2026',
    'filters': {
      'status': null,
      'date_from': '2026-09-01',
      'date_to': '2026-09-30',
    },
    'statuses': [
      {'key': 'present', 'label': 'Present'},
      {'key': 'absent', 'label': 'Absent'},
      {'key': 'late', 'label': 'Late'},
      {'key': 'leave', 'label': 'Leave'},
      {'key': 'short_leave', 'label': 'Short Leave'},
    ],
    'summary': {
      'today': null,
      'month': {
        'total': 11,
        'present': 2,
        'absent': 0,
        'late': 9,
        'leave': 0,
        'short_leave': 0,
      },
    },
    'records': [
      {
        'id': 12,
        'date': '2026-09-12',
        'date_label': '12 Sep 2026',
        'branch_name': 'Avicenna Campus',
        'status': 'late',
        'status_label': 'Late',
        'in_time_label': '09:30 AM',
        'out_time_label': '01:15 PM',
        'remarks': null,
        'marked_by': 'Miss Anam Mehmood',
      },
      {
        'id': 8,
        'date': '2026-09-08',
        'date_label': '08 Sep 2026',
        'branch_name': 'Ibn Sina Campus',
        'status': 'present',
        'status_label': 'Present',
        'in_time_label': '07:12 AM',
        'out_time_label': '01:15 PM',
        'remarks': null,
        'marked_by': 'Science Lyceum School',
      },
    ],
    'meta': {
      'current_page': 1,
      'last_page': 1,
      'per_page': 25,
      'total': 2,
      'from': 1,
      'to': 2,
    },
  };
}

Map<String, dynamic> _apiEnvelope(Map<String, dynamic> payload, {Map<String, dynamic>? meta}) {
  return {
    'status': 'success',
    'message': null,
    'data': {
      ...payload,
    }..remove('meta'),
    'meta': meta ?? payload['meta'],
  };
}

class _PagingAttendanceService extends TeacherAttendanceService {
  final queries = <TeacherAttendanceQuery>[];

  @override
  Future<TeacherAttendanceData> fetch(
    AuthSession session, {
    TeacherAttendanceQuery query = const TeacherAttendanceQuery(),
  }) async {
    queries.add(query);
    final records = (_samplePayload()['records'] as List).cast<Map<String, dynamic>>();
    if (query.page <= 1) {
      return TeacherAttendanceData.fromJson({
        ..._samplePayload(),
        'records': [records.first],
        'meta': {
          'current_page': 1,
          'last_page': 2,
          'per_page': 25,
          'total': 2,
          'from': 1,
          'to': 1,
        },
      });
    }

    return TeacherAttendanceData.fromJson({
      ..._samplePayload(),
      'records': [records.last],
      'meta': {
        'current_page': 2,
        'last_page': 2,
        'per_page': 25,
        'total': 2,
        'from': 2,
        'to': 2,
      },
    });
  }

  @override
  Future<BranchGeoFence> fetchLocation(AuthSession session) async {
    return const BranchGeoFence();
  }
}

class _FakeAttendanceService extends TeacherAttendanceService {
  _FakeAttendanceService(this.data, {this.error});

  final TeacherAttendanceData data;
  final Object? error;
  TeacherAttendanceQuery? lastQuery;

  @override
  Future<TeacherAttendanceData> fetch(
    AuthSession session, {
    TeacherAttendanceQuery query = const TeacherAttendanceQuery(),
  }) async {
    lastQuery = query;
    if (error != null) {
      throw error!;
    }
    return data;
  }

  @override
  Future<BranchGeoFence> fetchLocation(AuthSession session) async {
    return const BranchGeoFence();
  }

  @override
  Future<TeacherAttendanceMarkResult> markAttendance(
    AuthSession session, {
    required double latitude,
    required double longitude,
  }) async {
    throw const ApiException('Mark attendance is not configured in this test.');
  }
}

class _FakeDeviceLocationService implements DeviceLocationService {
  _FakeDeviceLocationService(this.location);

  final DeviceLocation location;
  var calls = 0;

  @override
  Future<DeviceLocation> currentPosition() async {
    calls += 1;
    return location;
  }
}

class _MarkingAttendanceService extends _FakeAttendanceService {
  _MarkingAttendanceService(
    super.data, {
    this.fence = const BranchGeoFence(),
    this.markResult,
    this.markError,
  });

  BranchGeoFence fence;
  TeacherAttendanceMarkResult? markResult;
  Object? markError;
  var locationFetches = 0;
  Map<String, double>? lastMark;

  @override
  Future<BranchGeoFence> fetchLocation(AuthSession session) async {
    locationFetches += 1;
    return fence;
  }

  @override
  Future<TeacherAttendanceMarkResult> markAttendance(
    AuthSession session, {
    required double latitude,
    required double longitude,
  }) async {
    lastMark = {'latitude': latitude, 'longitude': longitude};
    if (markError != null) {
      throw markError!;
    }
    return markResult ??
        const TeacherAttendanceMarkResult(message: 'Attendance marked successfully.');
  }
}

Finder _verticalAttendanceScrollable() {
  return find.byWidgetPredicate(
    (widget) => widget is Scrollable && widget.axisDirection == AxisDirection.down,
  );
}

void main() {
  test('parses teacher attendance summary and records', () {
    final data = TeacherAttendanceData.fromJson(_samplePayload());

    expect(data.heading, 'My Attendance — Sir Tanveer');
    expect(data.monthLabel, 'September 2026');
    expect(data.summary.today, isNull);
    expect(data.summary.month.total, 11);
    expect(data.summary.month.present, 2);
    expect(data.summary.month.late, 9);
    expect(data.records, hasLength(2));
    expect(data.records.first.displayDate, '12 Sep 2026');
    expect(data.records.first.displayBranch, 'Avicenna Campus');
    expect(data.records.first.displayStatus, 'Late');
    expect(data.records.first.displayIn, '09:30 AM');
    expect(data.records.first.displayOut, '01:15 PM');
    expect(data.records.first.displayRemarks, '—');
    expect(data.records.first.displayMarkedBy, 'Miss Anam Mehmood');
    expect(data.records.last.displayStatus, 'Present');
  });

  test('defaults the filter range to the current month', () {
    final controller = TeacherAttendanceController(
      session: _teacherSession(),
      clock: () => DateTime(2026, 9, 17),
    );

    expect(isoAttendanceDate(controller.dateFrom), '2026-09-01');
    expect(isoAttendanceDate(controller.dateTo), '2026-09-30');
    expect(controller.monthLabel, 'September 2026');
    expect(controller.hasActiveFilters, isFalse);
  });

  test('fetches page 1 with 25 records for the teacher', () async {
    http.Request? captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode(_apiEnvelope(_samplePayload())),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final data = await TeacherAttendanceService(
      client: ApiClient(httpClient: client),
    ).fetch(
      _teacherSession(),
      query: const TeacherAttendanceQuery(
        dateFrom: '2026-09-01',
        dateTo: '2026-09-30',
      ),
    );

    expect(captured, isNotNull);
    expect(captured!.method, 'GET');
    expect(captured!.url.path, '/api/mobile/teachers/my-attendance');
    expect(captured!.url.queryParameters['domain'], 'sls.localhost');
    expect(captured!.url.queryParameters.containsKey('branch_id'), isFalse);
    expect(captured!.url.queryParameters['page'], '1');
    expect(captured!.url.queryParameters['per_page'], '25');
    expect(captured!.url.queryParameters['date_from'], '2026-09-01');
    expect(captured!.url.queryParameters['date_to'], '2026-09-30');
    expect(captured!.headers['Authorization'], 'Bearer teacher.token');
    expect(data.summary.month.late, 9);
    expect(data.meta.perPage, 25);
    expect(data.meta.currentPage, 1);
  });

  test('sends status and date filters on page 1', () async {
    http.Request? captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode(_apiEnvelope(_samplePayload())),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    await TeacherAttendanceService(
      client: ApiClient(httpClient: client),
    ).fetch(
      _teacherSession(),
      query: const TeacherAttendanceQuery(
        status: 'present',
        dateFrom: '2026-09-01',
        dateTo: '2026-09-30',
        page: 1,
        perPage: 25,
      ),
    );

    expect(captured!.url.queryParameters['status'], 'present');
    expect(captured!.url.queryParameters['date_from'], '2026-09-01');
    expect(captured!.url.queryParameters['date_to'], '2026-09-30');
    expect(captured!.url.queryParameters['page'], '1');
    expect(captured!.url.queryParameters['per_page'], '25');
  });

  test('loads the next attendance page and appends records', () async {
    final fake = _PagingAttendanceService();
    final controller = TeacherAttendanceController(
      session: _teacherSession(),
      service: fake,
      clock: () => DateTime(2026, 9, 17),
    );

    await controller.load();

    expect(fake.queries.single.page, 1);
    expect(fake.queries.single.perPage, 25);
    expect(controller.data!.records, hasLength(1));
    expect(controller.data!.records.first.displayDate, '12 Sep 2026');
    expect(controller.hasMore, isTrue);

    await controller.loadMore();

    expect(fake.queries.last.page, 2);
    expect(fake.queries.last.perPage, 25);
    expect(controller.data!.records, hasLength(2));
    expect(controller.data!.records.last.displayDate, '08 Sep 2026');
    expect(controller.hasMore, isFalse);
  });

  testWidgets('shows monthly summary and attendance records', (tester) async {
    final fake = _FakeAttendanceService(
      TeacherAttendanceData.fromJson(_samplePayload()),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TeacherAttendanceView(
          session: _teacherSession(),
          service: fake,
          clock: () => DateTime(2026, 9, 17),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.notMarked), findsOneWidget);
    expect(find.text('11'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
    expect(find.text('9'), findsOneWidget);
    expect(find.text('01/09/2026'), findsOneWidget);
    expect(find.text('30/09/2026'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('12 Sep 2026'),
      120,
      scrollable: _verticalAttendanceScrollable(),
    );
    expect(find.text('Late'), findsWidgets);
    expect(find.text('09:30 AM'), findsOneWidget);
    expect(find.text('01:15 PM'), findsWidgets);
    expect(find.text('Miss Anam Mehmood'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('08 Sep 2026'),
      120,
      scrollable: _verticalAttendanceScrollable(),
    );
    expect(find.text('Present'), findsWidgets);
    expect(find.text('Science Lyceum School'), findsOneWidget);
  });

  testWidgets('load more fetches the next attendance page', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TeacherAttendanceView(
          session: _teacherSession(),
          service: _PagingAttendanceService(),
          clock: () => DateTime(2026, 9, 17),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('12 Sep 2026'), findsOneWidget);
    expect(find.text('08 Sep 2026'), findsNothing);

    await tester.scrollUntilVisible(
      find.text(AppStrings.loadMore),
      120,
      scrollable: _verticalAttendanceScrollable(),
    );
    await tester.tap(find.text(AppStrings.loadMore));
    await tester.pumpAndSettle();

    expect(find.text('12 Sep 2026'), findsOneWidget);
    expect(find.text('08 Sep 2026'), findsOneWidget);
    expect(find.text(AppStrings.loadMore), findsNothing);
  });

  testWidgets('tapping My Attendance opens the teacher attendance screen', (tester) async {
    final session = _teacherSession();
    final fake = _FakeAttendanceService(
      TeacherAttendanceData.fromJson(_samplePayload()),
    );

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.teacherAttendance) {
            return MaterialPageRoute(
              builder: (_) => TeacherAttendanceView(
                session: session,
                service: fake,
                clock: () => DateTime(2026, 9, 17),
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
        matching: find.text(AppStrings.myAttendance),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TeacherAttendanceView), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(TeacherAttendanceView),
        matching: find.text(AppStrings.notMarked),
      ),
      findsOneWidget,
    );
    expect(find.text('My Attendance — Sir Tanveer'), findsNothing);
  });

  testWidgets('shows empty attendance message', (tester) async {
    final fake = _FakeAttendanceService(
      TeacherAttendanceData.fromJson({
        ..._samplePayload(),
        'records': const [],
        'meta': {'total': 0, 'from': null, 'to': null},
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TeacherAttendanceView(
          session: _teacherSession(),
          service: fake,
          clock: () => DateTime(2026, 9, 17),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.notMarked), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(AppStrings.noAttendance),
      120,
      scrollable: _verticalAttendanceScrollable(),
    );
    expect(find.text(AppStrings.noAttendance), findsOneWidget);
  });

  testWidgets('shows API error and retry', (tester) async {
    final fake = _FakeAttendanceService(
      const TeacherAttendanceData(),
      error: const ApiException('No teacher profile is linked to this login for this branch.'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TeacherAttendanceView(session: _teacherSession(), service: fake),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No teacher profile is linked to this login for this branch.'),
      findsOneWidget,
    );
    expect(find.text(AppStrings.retry), findsOneWidget);
  });

  test('parses school location and treats a missing fence as not ready', () {
    final ready = BranchGeoFence.fromJson({
      'configured': true,
      'branch_id': 1,
      'branch_name': 'Avicenna Campus',
      'latitude': 32.2387062,
      'longitude': 74.1637894,
      'radius_meters': 3,
    });
    final missing = BranchGeoFence.fromJson({
      'configured': false,
      'branch_id': 1,
      'latitude': null,
      'longitude': null,
      'radius_meters': null,
    });

    expect(ready.isReady, isTrue);
    expect(ready.contains(32.2387062, 74.1637894), isTrue);
    expect(ready.contains(32.2392, 74.1637894), isFalse);
    expect(missing.isReady, isFalse);
  });

  test('fetches branch latitude, longitude and radius for mark attendance', () async {
    http.Request? captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode({
          'status': 'success',
          'message': null,
          'data': {
            'configured': true,
            'branch_id': 1,
            'branch_name': 'Avicenna Campus',
            'latitude': 32.2387062,
            'longitude': 74.1637894,
            'radius_meters': 3,
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final fence = await TeacherAttendanceService(
      client: ApiClient(httpClient: client),
    ).fetchLocation(_teacherSession());

    expect(captured, isNotNull);
    expect(captured!.method, 'GET');
    expect(captured!.url.path, '/api/mobile/teachers/my-attendance/location');
    expect(captured!.url.queryParameters['domain'], 'sls.localhost');
    expect(captured!.url.queryParameters['branch_id'], '1');
    expect(fence.isReady, isTrue);
    expect(fence.latitude, 32.2387062);
    expect(fence.longitude, 74.1637894);
    expect(fence.radiusMeters, 3);
  });

  test('posts device coordinates to mark attendance', () async {
    http.Request? captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode({
          'status': 'success',
          'message': 'Attendance marked successfully.',
          'data': {
            'distance_meters': 1.2,
            'radius_meters': 3,
            'status': 'present',
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final result = await TeacherAttendanceService(
      client: ApiClient(httpClient: client),
    ).markAttendance(
      _teacherSession(),
      latitude: 32.2387062,
      longitude: 74.1637894,
    );

    expect(captured, isNotNull);
    expect(captured!.method, 'POST');
    expect(captured!.url.path, '/api/mobile/teachers/my-attendance/mark');
    final body = jsonDecode(captured!.body) as Map<String, dynamic>;
    expect(body['domain'], 'sls.localhost');
    expect(body['branch_id'], 1);
    expect(body['latitude'], 32.2387062);
    expect(body['longitude'], 74.1637894);
    expect(result.message, 'Attendance marked successfully.');
  });

  testWidgets('shows a message when school location is not set', (tester) async {
    final fake = _MarkingAttendanceService(
      TeacherAttendanceData.fromJson(_samplePayload()),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TeacherAttendanceView(
          session: _teacherSession(),
          service: fake,
          locationService: _FakeDeviceLocationService(
            const DeviceLocation(latitude: 32.2387062, longitude: 74.1637894),
          ),
          clock: () => DateTime(2026, 9, 17),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('mark-attendance')));
    await tester.pump();

    expect(fake.locationFetches, 1);
    expect(fake.lastMark, isNull);
    expect(find.text(AppStrings.schoolLocationNotSet), findsOneWidget);
  });

  testWidgets('does not mark attendance when the teacher is outside the radius', (tester) async {
    final fake = _MarkingAttendanceService(
      TeacherAttendanceData.fromJson(_samplePayload()),
      fence: BranchGeoFence.fromJson({
        'configured': true,
        'branch_id': 1,
        'latitude': 32.2387062,
        'longitude': 74.1637894,
        'radius_meters': 3,
      }),
    );
    final location = _FakeDeviceLocationService(
      const DeviceLocation(latitude: 32.2392, longitude: 74.1637894),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TeacherAttendanceView(
          session: _teacherSession(),
          service: fake,
          locationService: location,
          clock: () => DateTime(2026, 9, 17),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('mark-attendance')));
    await tester.pump();

    expect(location.calls, 1);
    expect(fake.lastMark, isNull);
    expect(find.textContaining('outside the school radius'), findsOneWidget);
  });

  testWidgets('marks attendance when the teacher is inside the school radius', (tester) async {
    final fake = _MarkingAttendanceService(
      TeacherAttendanceData.fromJson(_samplePayload()),
      fence: BranchGeoFence.fromJson({
        'configured': true,
        'branch_id': 1,
        'latitude': 32.2387062,
        'longitude': 74.1637894,
        'radius_meters': 3,
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TeacherAttendanceView(
          session: _teacherSession(),
          service: fake,
          locationService: _FakeDeviceLocationService(
            const DeviceLocation(latitude: 32.2387062, longitude: 74.1637894),
          ),
          clock: () => DateTime(2026, 9, 17),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('mark-attendance')));
    await tester.pump();
    await tester.pump();

    expect(fake.lastMark, isNotNull);
    expect(fake.lastMark!['latitude'], 32.2387062);
    expect(fake.lastMark!['longitude'], 74.1637894);
    expect(find.text('Attendance marked successfully.'), findsOneWidget);
  });
}
