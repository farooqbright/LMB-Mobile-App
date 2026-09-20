import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../models/auth_session.dart';
import '../../models/teacher_timetable.dart';
import '../models/parent_timetable.dart';
import '../services/parent_timetable_service.dart';

class ParentTimetableController extends ChangeNotifier {
  ParentTimetableController({
    required this.session,
    ParentTimetableService? service,
    DateTime Function()? clock,
  })  : _service = service ?? ParentTimetableService(),
        _clock = clock ?? DateTime.now;

  final AuthSession session;
  final ParentTimetableService _service;
  final DateTime Function() _clock;

  DateTime get now => _clock();

  bool loading = true;
  String? errorMessage;
  ParentTimetableData? data;
  int? selectedDay;

  TeacherSchedule? get schedule => data?.schedule;

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
      selectedDay ??= result.schedule?.defaultDay(weekday: now.weekday);
    } on ApiException catch (error) {
      if (data == null) {
        errorMessage = error.message;
      }
    } catch (_) {
      if (data == null) {
        errorMessage = 'Unable to load the timetable. Please try again.';
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void selectDay(int day) {
    selectedDay = day;
    notifyListeners();
  }

  int get currentDay {
    return selectedDay ?? schedule?.defaultDay(weekday: now.weekday) ?? now.weekday;
  }
}
