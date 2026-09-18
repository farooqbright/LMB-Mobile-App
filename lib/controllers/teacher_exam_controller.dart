import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../models/auth_session.dart';
import '../models/teacher_exam.dart';
import '../services/teacher_exam_service.dart';

class TeacherExamController extends ChangeNotifier {
  TeacherExamController({
    required this.session,
    TeacherExamService? service,
  }) : _service = service ?? TeacherExamService();

  final AuthSession session;
  final TeacherExamService _service;

  bool loading = true;
  String? errorMessage;
  TeacherExamList? data;
  int? selectedSessionId;

  Future<void> load({bool refresh = false, int? academicSessionId}) async {
    if (!refresh) {
      loading = true;
      errorMessage = null;
      notifyListeners();
    }

    final sessionId = academicSessionId ?? selectedSessionId;

    try {
      data = await _service.fetchExams(
        session,
        academicSessionId: sessionId,
      );
      selectedSessionId = data?.session?.id ?? sessionId;
      errorMessage = null;
    } on ApiException catch (error) {
      if (data == null) {
        errorMessage = error.message;
      }
    } catch (_) {
      if (data == null) {
        errorMessage = 'Unable to load exams. Please try again.';
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> selectSession(int sessionId) async {
    if (selectedSessionId == sessionId && data != null) return;
    selectedSessionId = sessionId;
    await load(academicSessionId: sessionId);
  }
}
