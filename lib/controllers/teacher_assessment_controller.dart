import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../models/auth_session.dart';
import '../models/teacher_assessment.dart';
import '../services/teacher_assessment_service.dart';

class TeacherAssessmentController extends ChangeNotifier {
  TeacherAssessmentController({
    required this.session,
    TeacherAssessmentService? service,
  }) : _service = service ?? TeacherAssessmentService();

  final AuthSession session;
  final TeacherAssessmentService _service;

  bool loading = true;
  String? errorMessage;
  TeacherAssessmentClasses? data;

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
        errorMessage = 'Unable to load tests and homework. Please try again.';
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
