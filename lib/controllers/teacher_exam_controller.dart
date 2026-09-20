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
  bool loadingMore = false;
  String? errorMessage;
  TeacherExamList? data;
  int? selectedSessionId;
  int page = 1;

  static const int pageSize = 25;

  bool get hasMore => data?.hasMore ?? false;

  Future<void> load({bool refresh = false, int? academicSessionId}) async {
    if (!refresh) {
      loading = true;
      errorMessage = null;
      notifyListeners();
    }

    page = 1;
    final sessionId = academicSessionId ?? selectedSessionId;

    try {
      data = await _service.fetchExams(
        session,
        academicSessionId: sessionId,
        page: 1,
        perPage: pageSize,
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
      loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (!hasMore || loading || loadingMore) return;

    loadingMore = true;
    notifyListeners();

    try {
      final nextPage = page + 1;
      final result = await _service.fetchExams(
        session,
        academicSessionId: selectedSessionId,
        page: nextPage,
        perPage: pageSize,
      );
      data = (data ?? result).mergePage(result);
      page = result.meta.currentPage;
    } catch (_) {
      // Keep the loaded page if more exams fail.
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> selectSession(int sessionId) async {
    if (selectedSessionId == sessionId && data != null) return;
    selectedSessionId = sessionId;
    await load(academicSessionId: sessionId);
  }
}
