import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../models/auth_session.dart';
import '../models/teacher_salary.dart';
import '../services/teacher_salary_service.dart';

class TeacherSalaryController extends ChangeNotifier {
  TeacherSalaryController({
    required this.session,
    TeacherSalaryService? service,
  }) : _service = service ?? TeacherSalaryService();

  final AuthSession session;
  final TeacherSalaryService _service;

  bool loading = false;
  bool loadingMore = false;
  bool loadingSlip = false;
  String? errorMessage;
  TeacherSalaryData? data;
  TeacherSalaryItem? selectedSlip;

  Future<void> load({bool refresh = false}) async {
    if (loading) return;
    loading = true;
    if (!refresh) errorMessage = null;
    notifyListeners();

    try {
      final next = await _service.fetch(session, page: 1);
      data = next;
      errorMessage = null;
    } on ApiException catch (error) {
      errorMessage = error.message;
      if (!refresh) data = null;
    } catch (_) {
      errorMessage = 'Unable to load salary slips. Please try again.';
      if (!refresh) data = null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    final current = data;
    if (loading || loadingMore || current == null || !current.meta.hasMore) {
      return;
    }

    loadingMore = true;
    notifyListeners();

    try {
      final next = await _service.fetch(
        session,
        page: current.meta.currentPage + 1,
        perPage: current.meta.perPage,
      );
      data = TeacherSalaryData(
        summary: next.summary,
        items: [...current.items, ...next.items],
        meta: next.meta,
      );
    } on ApiException catch (error) {
      errorMessage = error.message;
    } catch (_) {
      errorMessage = 'Unable to load more salary slips.';
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }

  Future<TeacherSalaryItem?> openSlip(int itemId) async {
    loadingSlip = true;
    notifyListeners();
    try {
      final slip = await _service.fetchSlip(session, itemId);
      selectedSlip = slip;
      return slip;
    } on ApiException catch (error) {
      errorMessage = error.message;
      return null;
    } catch (_) {
      errorMessage = 'Unable to open salary slip.';
      return null;
    } finally {
      loadingSlip = false;
      notifyListeners();
    }
  }
}
