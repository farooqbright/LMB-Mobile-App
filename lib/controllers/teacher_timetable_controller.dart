import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../models/auth_session.dart';
import '../models/teacher_timetable.dart';
import '../services/teacher_timetable_service.dart';

class TeacherTimetableController extends ChangeNotifier {
  TeacherTimetableController({
    required this.session,
    TeacherTimetableService? service,
    DateTime Function()? clock,
  })  : _service = service ?? TeacherTimetableService(),
        _clock = clock ?? _systemTime;

  final AuthSession session;
  final TeacherTimetableService _service;
  final DateTime Function() _clock;

  static DateTime _systemTime() => DateTime.now();

  DateTime get now => _clock();

  bool loading = true;
  String? errorMessage;
  TeacherTimetableData? data;
  final Map<int, int> selectedDayBySchedule = {};

  Future<void> load({bool refresh = false}) async {
    if (!refresh) {
      loading = true;
      errorMessage = null;
      notifyListeners();
    }

    try {
      final result = await _service.fetch(session);
      data = result;
      errorMessage = null;
      _ensureSelectedDays();
    } on ApiException catch (error) {
      if (data == null) {
        errorMessage = error.message;
      }
    } catch (_) {
      if (data == null) {
        errorMessage = 'Unable to load your timetable. Please try again.';
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void selectDay(TeacherSchedule schedule, int day) {
    selectedDayBySchedule[schedule.key] = day;
    notifyListeners();
  }

  int selectedDayFor(TeacherSchedule schedule) {
    return selectedDayBySchedule[schedule.key] ??
        schedule.defaultDay(weekday: now.weekday);
  }

  void _ensureSelectedDays() {
    final branches = data?.branches ?? const <TeacherTimetableBranch>[];
    for (final branch in branches) {
      for (final schedule in branch.schedules) {
        selectedDayBySchedule.putIfAbsent(
          schedule.key,
          () => schedule.defaultDay(weekday: now.weekday),
        );
      }
    }
  }
}
