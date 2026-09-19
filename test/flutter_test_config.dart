import 'dart:async';

import 'package:lmssystem/models/auth_session.dart';
import 'package:lmssystem/models/teacher_attendance.dart';
import 'package:lmssystem/models/teacher_timetable.dart';
import 'package:lmssystem/parent/models/parent_attendance.dart';
import 'package:lmssystem/parent/screens/parent_dashboard_view.dart';
import 'package:lmssystem/parent/services/parent_attendance_service.dart';
import 'package:lmssystem/services/teacher_attendance_service.dart';
import 'package:lmssystem/services/teacher_timetable_service.dart';
import 'package:lmssystem/views/dashboards/teacher_dashboard_view.dart';

class _SilentAttendanceService extends TeacherAttendanceService {
  @override
  Future<TeacherAttendanceData> fetch(
    AuthSession session, {
    TeacherAttendanceQuery query = const TeacherAttendanceQuery(),
  }) async {
    return const TeacherAttendanceData();
  }
}

class _SilentTimetableService extends TeacherTimetableService {
  @override
  Future<TeacherTimetableData> fetch(AuthSession session) async {
    return const TeacherTimetableData(teacher: TimetableTeacher(), branches: []);
  }
}

class _SilentParentAttendanceService extends ParentAttendanceService {
  @override
  Future<ParentAttendanceData> fetch(
    AuthSession session, {
    ParentAttendanceQuery query = const ParentAttendanceQuery(),
  }) async {
    return const ParentAttendanceData();
  }
}

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TeacherDashboardView.debugAttendanceService = _SilentAttendanceService();
  TeacherDashboardView.debugTimetableService = _SilentTimetableService();
  ParentDashboardView.debugAttendanceService = _SilentParentAttendanceService();
  await testMain();
}
