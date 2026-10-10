import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../models/auth_session.dart';
import '../models/teacher_curriculum.dart';
import '../services/teacher_curriculum_service.dart';

class TeacherCurriculumController extends ChangeNotifier {
  TeacherCurriculumController({
    required this.session,
    TeacherCurriculumService? service,
  }) : _service = service ?? TeacherCurriculumService();

  final AuthSession session;
  final TeacherCurriculumService _service;

  bool loading = true;
  String? errorMessage;
  TeacherCurriculumSubjects? data;

  Future<void> load({bool refresh = false}) async {
    if (!refresh) {
      loading = true;
      errorMessage = null;
      notifyListeners();
    }

    try {
      data = await _service.fetchSubjects(session);
      errorMessage = null;
    } on ApiException catch (error) {
      if (data == null) {
        errorMessage = error.message;
      }
    } catch (_) {
      if (data == null) {
        errorMessage = 'Unable to load your subjects. Please try again.';
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
