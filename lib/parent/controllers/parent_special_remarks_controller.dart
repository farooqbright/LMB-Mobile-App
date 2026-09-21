import 'package:flutter/foundation.dart';

import '../../core/constants/app_strings.dart';
import '../../core/network/api_exception.dart';
import '../../models/auth_session.dart';
import '../../models/teacher_attendance.dart';
import '../models/parent_special_remarks.dart';
import '../services/parent_special_remarks_service.dart';

enum ParentRemarksPeriod { today, lastWeek, all, date }

class ParentSpecialRemarksController extends ChangeNotifier {
  ParentSpecialRemarksController({
    required this.session,
    ParentSpecialRemarksService? service,
    DateTime Function()? clock,
  })  : _service = service ?? ParentSpecialRemarksService(),
        _clock = clock ?? DateTime.now {
    selectedDate = DateTime(now.year, now.month, now.day);
  }

  static const int pageSize = 25;

  final AuthSession session;
  final ParentSpecialRemarksService _service;
  final DateTime Function() _clock;

  DateTime get now => _clock();

  ParentRemarksPeriod period = ParentRemarksPeriod.today;
  late DateTime selectedDate;
  int page = 1;

  bool loading = true;
  bool loadingMore = false;
  String? errorMessage;
  ParentSpecialRemarksData? data;

  String get periodKey {
    switch (period) {
      case ParentRemarksPeriod.today:
        return 'today';
      case ParentRemarksPeriod.lastWeek:
        return 'last_week';
      case ParentRemarksPeriod.all:
        return 'all';
      case ParentRemarksPeriod.date:
        return 'date';
    }
  }

  String get rangeLabel {
    final fromApi = data?.rangeLabel?.trim();
    if (fromApi != null && fromApi.isNotEmpty && data?.period == periodKey) {
      return fromApi;
    }

    switch (period) {
      case ParentRemarksPeriod.today:
        return '${AppStrings.attendanceToday} · ${displayAttendanceLongDate(DateTime(now.year, now.month, now.day))}';
      case ParentRemarksPeriod.lastWeek:
        return '${AppStrings.lastWeek} · ${displayAttendanceLongDate(attendanceLastWeekStart(now))} — ${displayAttendanceLongDate(attendanceLastWeekEnd(now))}';
      case ParentRemarksPeriod.all:
        return 'All remarks';
      case ParentRemarksPeriod.date:
        return displayAttendanceLongDate(selectedDate);
    }
  }

  String get summaryLine {
    final count = data?.remarksCount ?? 0;
    final remarkWord = count == 1 ? 'remark' : 'remarks';
    final newCount = data?.newCount ?? 0;
    final parts = [
      '${AppStrings.showing}: $rangeLabel',
      '$count $remarkWord',
      if (newCount > 0) '$newCount new',
    ];
    return parts.join(' · ');
  }

  bool get hasMore => data?.hasMore ?? false;

  ParentSpecialRemarksQuery queryFor({int? page}) {
    return ParentSpecialRemarksQuery(
      period: periodKey,
      date: isoAttendanceDate(selectedDate),
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
        errorMessage = 'Unable to load special remarks. Please try again.';
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

  Future<void> selectPeriod(ParentRemarksPeriod value) async {
    period = value;
    if (value == ParentRemarksPeriod.today) {
      selectedDate = DateTime(now.year, now.month, now.day);
    }
    notifyListeners();
    await load();
  }

  Future<void> selectDate(DateTime value) async {
    var next = DateTime(value.year, value.month, value.day);
    final today = DateTime(now.year, now.month, now.day);
    if (next.isAfter(today)) {
      next = today;
    }
    selectedDate = next;
    period = ParentRemarksPeriod.date;
    notifyListeners();
    await load();
  }
}
