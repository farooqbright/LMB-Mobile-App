import 'package:flutter/foundation.dart';

import '../core/constants/app_strings.dart';
import '../core/network/api_exception.dart';
import '../models/auth_session.dart';
import '../models/teacher_attendance.dart';
import '../services/device_location_service.dart';
import '../services/teacher_attendance_service.dart';

class TeacherAttendanceController extends ChangeNotifier {
  TeacherAttendanceController({
    required this.session,
    TeacherAttendanceService? service,
    DeviceLocationService? locationService,
    DateTime Function()? clock,
  })  : _service = service ?? TeacherAttendanceService(),
        _locationService = locationService ?? const GeolocatorDeviceLocationService(),
        _clock = clock ?? _systemTime {
    final now = this.now;
    dateFrom = attendanceMonthStart(now);
    dateTo = attendanceMonthEnd(now);
  }

  static const int pageSize = 25;

  final AuthSession session;
  final TeacherAttendanceService _service;
  final DeviceLocationService _locationService;
  final DateTime Function() _clock;

  static DateTime _systemTime() => DateTime.now();

  DateTime get now => _clock();

  String? status;
  late DateTime dateFrom;
  late DateTime dateTo;
  int page = 1;

  bool loading = true;
  bool loadingMore = false;
  bool marking = false;
  String? errorMessage;
  TeacherAttendanceData? data;

  bool get alreadyMarkedToday => data?.summary.today != null;

  TeacherAttendanceQuery queryFor({int? page}) {
    return TeacherAttendanceQuery(
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
        isoAttendanceDate(dateFrom) != isoAttendanceDate(attendanceMonthStart(now)) ||
        isoAttendanceDate(dateTo) != isoAttendanceDate(attendanceMonthEnd(now));
  }

  bool get hasMore => data?.hasMore ?? false;

  String get monthLabel => data?.monthLabel?.trim().isNotEmpty == true
      ? data!.monthLabel!.trim()
      : attendanceMonthTitle(now);

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
        errorMessage = 'Unable to load your attendance. Please try again.';
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

    final nextPage = (data?.meta.currentPage ?? page) + 1;

    try {
      final result = await _service.fetch(session, query: queryFor(page: nextPage));
      data = data?.mergePage(result) ?? result;
      page = result.meta.currentPage;
    } catch (_) {
      // Keep the records already on screen if the next page fails.
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
    dateFrom = attendanceMonthStart(now);
    dateTo = attendanceMonthEnd(now);
    return load();
  }

  Future<String> markAttendance() async {
    if (marking) {
      throw const ApiException(AppStrings.markingAttendance);
    }
    if (alreadyMarkedToday) {
      throw const ApiException(AppStrings.attendanceAlreadyMarked);
    }

    marking = true;
    notifyListeners();

    try {
      final fence = await _service.fetchLocation(session);
      if (!fence.isReady) {
        throw const ApiException(AppStrings.schoolLocationNotSet);
      }

      final here = await _locationService.currentPosition();
      if (!fence.contains(here.latitude, here.longitude)) {
        throw ApiException(fence.outsideMessage(here.latitude, here.longitude));
      }

      final result = await _service.markAttendance(
        session,
        latitude: here.latitude,
        longitude: here.longitude,
      );
      await load(refresh: true);
      return (result.message ?? '').trim().isEmpty
          ? AppStrings.attendanceMarked
          : result.message!.trim();
    } finally {
      marking = false;
      notifyListeners();
    }
  }
}
