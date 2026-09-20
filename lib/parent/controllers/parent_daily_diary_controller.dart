import 'package:flutter/foundation.dart';

import '../../core/constants/app_strings.dart';
import '../../core/network/api_exception.dart';
import '../../models/auth_session.dart';
import '../../models/teacher_attendance.dart';
import '../models/parent_daily_diary.dart';
import '../services/parent_daily_diary_service.dart';

enum ParentDiaryPeriod { today, lastWeek, date }

class ParentDailyDiaryController extends ChangeNotifier {
  ParentDailyDiaryController({
    required this.session,
    ParentDailyDiaryService? service,
    DateTime Function()? clock,
  })  : _service = service ?? ParentDailyDiaryService(),
        _clock = clock ?? DateTime.now {
    selectedDate = DateTime(now.year, now.month, now.day);
  }

  final AuthSession session;
  final ParentDailyDiaryService _service;
  final DateTime Function() _clock;

  DateTime get now => _clock();

  ParentDiaryPeriod period = ParentDiaryPeriod.today;
  late DateTime selectedDate;

  bool loading = true;
  String? errorMessage;
  ParentDailyDiaryData? data;

  String get periodKey {
    switch (period) {
      case ParentDiaryPeriod.today:
        return 'today';
      case ParentDiaryPeriod.lastWeek:
        return 'last_week';
      case ParentDiaryPeriod.date:
        return 'date';
    }
  }

  String get rangeLabel {
    final fromApi = data?.rangeLabel?.trim();
    if (fromApi != null && fromApi.isNotEmpty && data?.period == periodKey) {
      return fromApi;
    }

    switch (period) {
      case ParentDiaryPeriod.today:
        return '${AppStrings.attendanceToday} · ${displayAttendanceLongDate(DateTime(now.year, now.month, now.day))}';
      case ParentDiaryPeriod.lastWeek:
        return '${AppStrings.lastWeek} · ${displayAttendanceLongDate(attendanceLastWeekStart(now))} — ${displayAttendanceLongDate(attendanceLastWeekEnd(now))}';
      case ParentDiaryPeriod.date:
        return displayAttendanceLongDate(selectedDate);
    }
  }

  String get summaryLine {
    final days = data?.daysCount ?? 0;
    final subjects = data?.subjectsCount ?? 0;
    final dayWord = days == 1 ? 'day' : 'days';
    final subjectWord = subjects == 1 ? 'subject' : 'subjects';
    return '${AppStrings.showing}: $rangeLabel · $days $dayWord · $subjects $subjectWord';
  }

  ParentDailyDiaryQuery get query {
    return ParentDailyDiaryQuery(
      period: periodKey,
      date: isoAttendanceDate(selectedDate),
    );
  }

  Future<void> load({bool refresh = false}) async {
    if (!refresh) {
      loading = true;
      errorMessage = null;
      notifyListeners();
    }

    try {
      final result = await _service.fetch(session, query: query);
      data = result;
      errorMessage = null;
    } on ApiException catch (error) {
      if (data == null) {
        errorMessage = error.message;
      }
    } catch (_) {
      if (data == null) {
        errorMessage = 'Unable to load the daily diary. Please try again.';
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> selectPeriod(ParentDiaryPeriod value) async {
    period = value;
    if (value == ParentDiaryPeriod.today) {
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
    period = ParentDiaryPeriod.date;
    notifyListeners();
    await load();
  }
}
