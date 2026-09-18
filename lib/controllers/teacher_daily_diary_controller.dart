import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../models/auth_session.dart';
import '../models/teacher_daily_diary.dart';
import '../services/teacher_daily_diary_service.dart';

class TeacherDailyDiaryController extends ChangeNotifier {
  TeacherDailyDiaryController({
    required this.session,
    TeacherDailyDiaryService? service,
  }) : _service = service ?? TeacherDailyDiaryService();

  final AuthSession session;
  final TeacherDailyDiaryService _service;

  bool loading = true;
  String? errorMessage;
  TeacherDailyDiaryClasses? data;

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
        errorMessage = 'Unable to load your classes. Please try again.';
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
