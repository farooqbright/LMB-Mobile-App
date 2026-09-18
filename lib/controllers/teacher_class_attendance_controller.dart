import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../models/auth_session.dart';
import '../models/teacher_class_attendance.dart';
import '../services/teacher_class_attendance_service.dart';

class TeacherClassAttendanceController extends ChangeNotifier {
  TeacherClassAttendanceController({
    required this.session,
    TeacherClassAttendanceService? service,
  }) : _service = service ?? TeacherClassAttendanceService();

  final AuthSession session;
  final TeacherClassAttendanceService _service;

  bool loading = true;
  String? errorMessage;
  TeacherClassAttendanceClasses? data;

  Future<void> load({bool refresh = false}) async {
    if (!refresh) {
      loading = true;
      errorMessage = null;
      notifyListeners();
    }

    try {
      data = await _service.fetchClasses(session);
      errorMessage = null;
    } on ApiException catch (error) {
      if (data == null) {
        errorMessage = error.message;
      }
    } catch (_) {
      if (data == null) {
        errorMessage = 'Unable to load class attendance. Please try again.';
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
