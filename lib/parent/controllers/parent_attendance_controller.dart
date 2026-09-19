import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../models/auth_session.dart';
import '../../models/teacher_attendance.dart';
import '../models/parent_attendance.dart';
import '../services/parent_attendance_service.dart';

class ParentAttendanceController extends ChangeNotifier {
  ParentAttendanceController({
    required this.session,
    ParentAttendanceService? service,
    DateTime Function()? clock,
  })  : _service = service ?? ParentAttendanceService(),
        _clock = clock ?? DateTime.now {
    final now = this.now;
    dateFrom = attendanceLastMonthStart(now);
    dateTo = attendanceLastMonthEnd(now);
  }

  static const int pageSize = 25;

  final AuthSession session;
  final ParentAttendanceService _service;
  final DateTime Function() _clock;

  DateTime get now => _clock();

  String? status;
  late DateTime dateFrom;
  late DateTime dateTo;
  int page = 1;

  bool loading = true;
  bool loadingMore = false;
  String? errorMessage;
  ParentAttendanceData? data;

  ParentAttendanceQuery queryFor({int? page}) {
    return ParentAttendanceQuery(
      status: status,
      dateFrom: isoAttendanceDate(dateFrom),
      dateTo: isoAttendanceDate(dateTo),
      page: page ?? this.page,
      perPage: pageSize,
    );
  }

  bool get hasActiveFilters {
    final now = this.now;
    return (status != null && status!.isNotEmpty) ||
        isoAttendanceDate(dateFrom) != isoAttendanceDate(attendanceLastMonthStart(now)) ||
        isoAttendanceDate(dateTo) != isoAttendanceDate(attendanceLastMonthEnd(now));
  }

  bool get hasMore => data?.hasMore ?? false;

  Future<void> load({bool refresh = false}) async {
    page = 1;
    if (!refresh) {
      loading = true;
      errorMessage = null;
      notifyListeners();
    }

    try {
      final result = await _service.fetch(session, query: queryFor(page: 1));
      data = result;
      page = result.meta.currentPage;
      errorMessage = null;
    } on ApiException catch (error) {
      if (data == null) {
        errorMessage = error.message;
      }
    } catch (_) {
      if (data == null) {
        errorMessage = 'Unable to load attendance. Please try again.';
      }
    } finally {
      loading = false;
      loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (loading || loadingMore || !hasMore) return;

    loadingMore = true;
    notifyListeners();

    try {
      final nextPage = page + 1;
      final result = await _service.fetch(session, query: queryFor(page: nextPage));
      data = (data ?? result).mergePage(result);
      page = result.meta.currentPage;
    } catch (_) {
      // Keep the loaded page if more records fail.
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }

  void setStatus(String? value) {
    status = (value == null || value.isEmpty) ? null : value;
    notifyListeners();
  }

  void setDateFrom(DateTime value) {
    dateFrom = DateTime(value.year, value.month, value.day);
    if (dateTo.isBefore(dateFrom)) {
      dateTo = dateFrom;
    }
    notifyListeners();
  }

  void setDateTo(DateTime value) {
    dateTo = DateTime(value.year, value.month, value.day);
    if (dateTo.isBefore(dateFrom)) {
      dateFrom = dateTo;
    }
    notifyListeners();
  }

  Future<void> applyFilters() => load();

  Future<void> clearFilters() {
    status = null;
    final now = this.now;
    dateFrom = attendanceLastMonthStart(now);
    dateTo = attendanceLastMonthEnd(now);
    return load();
  }

  Future<void> showAllHistory() {
    status = null;
    final now = this.now;
    dateFrom = DateTime(now.year - 2, now.month, now.day);
    dateTo = DateTime(now.year, now.month, now.day);
    return load();
  }
}
