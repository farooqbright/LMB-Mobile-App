import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../models/auth_session.dart';
import '../models/parent_curriculum.dart';
import '../services/parent_curriculum_service.dart';

class ParentCurriculumController extends ChangeNotifier {
  ParentCurriculumController({
    required this.session,
    ParentCurriculumService? service,
  }) : _service = service ?? ParentCurriculumService();

  final AuthSession session;
  final ParentCurriculumService _service;

  bool loading = true;
  String? errorMessage;
  ParentCurriculumSubjects? data;

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
      errorMessage = data == null ? error.message : errorMessage;
    } catch (_) {
      errorMessage = data == null
          ? 'Unable to load curriculum. Please try again.'
          : errorMessage;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
