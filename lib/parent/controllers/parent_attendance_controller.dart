import 'package:flutter/foundation.dart';

import '../../core/constants/app_strings.dart';
import '../../core/network/api_exception.dart';
import '../../models/auth_session.dart';
import '../../models/teacher_attendance.dart';
import '../models/parent_attendance.dart';
import '../services/parent_attendance_service.dart';

enum ParentAttendancePeriod { month, lastWeek, lastMonth, custom }

class ParentAttendanceController extends ChangeNotifier {
  ParentAttendanceController({
    required this.session,
    ParentAttendanceService? service,
    DateTime Function()? clock,
  })  : _service = service ?? ParentAttendanceService(),
        _clock = clock ?? DateTime.now {
    _applyPeriodDates();
  }

  static const int pageSize = 100;
  static const int maxCustomDays = 366;

  final AuthSession session;
  final ParentAttendanceService _service;
  final DateTime Function() _clock;

  DateTime get now => _clock();

  ParentAttendancePeriod period = ParentAttendancePeriod.month;
  late DateTime dateFrom;
  late DateTime dateTo;
  int page = 1;

  bool loading = true;
  bool loadingMore = false;
  String? errorMessage;
  ParentAttendanceData? data;

  String get rangeLabel {
    switch (period) {
      case ParentAttendancePeriod.month:
        return attendanceMonthTitle(dateFrom);
      case ParentAttendancePeriod.lastWeek:
        return '${AppStrings.lastWeek} · ${displayAttendanceLongDate(dateFrom)} — ${displayAttendanceLongDate(dateTo)}';
      case ParentAttendancePeriod.lastMonth:
        return '${AppStrings.lastMonth} · ${attendanceMonthTitle(dateFrom)}';
      case ParentAttendancePeriod.custom:
        return '${displayAttendanceLongDate(dateFrom)} — ${displayAttendanceLongDate(dateTo)}';
    }
  }

  ParentAttendanceQuery queryFor({int? page}) {
    return ParentAttendanceQuery(
      dateFrom: isoAttendanceDate(dateFrom),
      dateTo: isoAttendanceDate(dateTo),
      page: page ?? this.page,
      perPage: pageSize,
    );
  }

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
    if (loading || loadingMore || !(data?.hasMore ?? false)) return;

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

  Future<void> selectPeriod(ParentAttendancePeriod value) async {
    if (value == ParentAttendancePeriod.custom) {
      if (period != ParentAttendancePeriod.custom) {
        dateFrom = attendanceMonthStart(now);
        dateTo = attendanceLast30DaysEnd(now);
      }
      period = value;
      notifyListeners();
      return;
    }

    period = value;
    _applyPeriodDates();
    notifyListeners();
    await load();
  }

  void setDateFrom(DateTime value) {
    dateFrom = DateTime(value.year, value.month, value.day);
    if (dateTo.isBefore(dateFrom)) {
      dateTo = dateFrom;
    }
    _capCustomRange();
    notifyListeners();
  }

  void setDateTo(DateTime value) {
    dateTo = DateTime(value.year, value.month, value.day);
    if (dateTo.isBefore(dateFrom)) {
      dateFrom = dateTo;
    }
    _capCustomRange();
    notifyListeners();
  }

  Future<void> applyFilters() => load();

  Future<void> resetFilters() => selectPeriod(ParentAttendancePeriod.month);

  void _applyPeriodDates() {
    final now = this.now;
    switch (period) {
      case ParentAttendancePeriod.month:
        dateFrom = attendanceMonthStart(now);
        dateTo = attendanceMonthEnd(now);
      case ParentAttendancePeriod.lastWeek:
        dateFrom = attendanceLastWeekStart(now);
        dateTo = attendanceLastWeekEnd(now);
      case ParentAttendancePeriod.lastMonth:
        dateFrom = attendanceLastMonthStart(now);
        dateTo = attendanceLastMonthEnd(now);
      case ParentAttendancePeriod.custom:
        break;
    }
  }

  void _capCustomRange() {
    if (dateTo.difference(dateFrom).inDays <= maxCustomDays) return;
    dateTo = dateFrom.add(const Duration(days: maxCustomDays));
  }
}
