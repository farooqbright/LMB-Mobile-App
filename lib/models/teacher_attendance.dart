import 'package:flutter/material.dart';

class TeacherAttendanceData {
  const TeacherAttendanceData({
    this.teacherName,
    this.branchName,
    this.personType = 'teacher',
    this.monthLabel,
    this.filters = const TeacherAttendanceFilters(),
    this.statuses = const [],
    this.summary = const TeacherAttendanceSummary(),
    this.records = const [],
    this.meta = const TeacherAttendanceMeta(),
  });

  final String? teacherName;
  final String? branchName;
  final String personType;
  final String? monthLabel;
  final TeacherAttendanceFilters filters;
  final List<AttendanceStatusOption> statuses;
  final TeacherAttendanceSummary summary;
  final List<TeacherAttendanceRecord> records;
  final TeacherAttendanceMeta meta;

  bool get isEmpty => records.isEmpty;

  bool get hasMore => meta.hasMore;

  String get heading {
    final name = teacherName?.trim();
    if (name == null || name.isEmpty) return 'My Attendance';
    return 'My Attendance — $name';
  }

  TeacherAttendanceData mergePage(TeacherAttendanceData next) {
    final seen = <int>{
      for (final record in records)
        if (record.id != null) record.id!,
    };

    return TeacherAttendanceData(
      teacherName: teacherName ?? next.teacherName,
      branchName: branchName ?? next.branchName,
      personType: personType,
      monthLabel: monthLabel ?? next.monthLabel,
      filters: next.filters,
      statuses: statuses.isNotEmpty ? statuses : next.statuses,
      summary: summary,
      records: [
        ...records,
        for (final record in next.records)
          if (record.id == null || seen.add(record.id!)) record,
      ],
      meta: next.meta,
    );
  }

  factory TeacherAttendanceData.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? metaJson,
  }) {
    final teacher = _asMap(json['teacher']) ?? const <String, dynamic>{};
    final branch = _asMap(json['branch']);
    final branches = json['branches'];
    String? branchName = _asString(branch?['branch_name']);
    if (branchName == null && branches is List && branches.isNotEmpty) {
      branchName = _asString(_asMap(branches.first)?['branch_name']);
    }

    return TeacherAttendanceData(
      teacherName: _asString(teacher['full_name']) ?? _asString(json['teacher_name']),
      branchName: branchName,
      personType: _asString(teacher['person_type']) ??
          _asString(json['person_type']) ??
          'teacher',
      monthLabel: _asString(json['month_label']),
      filters: TeacherAttendanceFilters.fromJson(_asMap(json['filters']) ?? const {}),
      statuses: _asObjectList(json['statuses'], AttendanceStatusOption.fromJson),
      summary: TeacherAttendanceSummary.fromJson(_asMap(json['summary']) ?? const {}),
      records: _asObjectList(json['records'], TeacherAttendanceRecord.fromJson),
      meta: TeacherAttendanceMeta.fromJson(
        metaJson ?? _asMap(json['meta']) ?? const {},
      ),
    );
  }
}

class TeacherAttendanceFilters {
  const TeacherAttendanceFilters({
    this.status,
    this.dateFrom,
    this.dateTo,
  });

  final String? status;
  final String? dateFrom;
  final String? dateTo;

  factory TeacherAttendanceFilters.fromJson(Map<String, dynamic> json) {
    return TeacherAttendanceFilters(
      status: _asString(json['status']),
      dateFrom: _asString(json['date_from']),
      dateTo: _asString(json['date_to']),
    );
  }
}

class AttendanceStatusOption {
  const AttendanceStatusOption({required this.key, required this.label});

  final String key;
  final String label;

  factory AttendanceStatusOption.fromJson(Map<String, dynamic> json) {
    return AttendanceStatusOption(
      key: _asString(json['key']) ?? '',
      label: _asString(json['label']) ?? '',
    );
  }
}

class TeacherAttendanceSummary {
  const TeacherAttendanceSummary({
    this.today,
    this.month = const AttendanceMonthCounts(),
  });

  final AttendanceToday? today;
  final AttendanceMonthCounts month;

  factory TeacherAttendanceSummary.fromJson(Map<String, dynamic> json) {
    final todayJson = _asMap(json['today']);
    return TeacherAttendanceSummary(
      today: todayJson == null ? null : AttendanceToday.fromJson(todayJson),
      month: AttendanceMonthCounts.fromJson(_asMap(json['month']) ?? const {}),
    );
  }
}

class AttendanceToday {
  const AttendanceToday({
    this.status,
    this.statusLabel,
    this.secondaryStatus,
    this.secondaryStatusLabel,
    this.inTimeLabel,
    this.outTimeLabel,
  });

  final String? status;
  final String? statusLabel;
  final String? secondaryStatus;
  final String? secondaryStatusLabel;
  final String? inTimeLabel;
  final String? outTimeLabel;

  factory AttendanceToday.fromJson(Map<String, dynamic> json) {
    return AttendanceToday(
      status: _asString(json['status']),
      statusLabel: _asString(json['status_label']),
      secondaryStatus: _asString(json['secondary_status']),
      secondaryStatusLabel: _asString(json['secondary_status_label']),
      inTimeLabel: _asString(json['in_time_label']),
      outTimeLabel: _asString(json['out_time_label']),
    );
  }
}

class AttendanceMonthCounts {
  const AttendanceMonthCounts({
    this.total = 0,
    this.present = 0,
    this.absent = 0,
    this.late = 0,
    this.leave = 0,
    this.shortLeave = 0,
  });

  final int total;
  final int present;
  final int absent;
  final int late;
  final int leave;
  final int shortLeave;

  factory AttendanceMonthCounts.fromJson(Map<String, dynamic> json) {
    return AttendanceMonthCounts(
      total: _asInt(json['total']) ?? 0,
      present: _asInt(json['present']) ?? 0,
      absent: _asInt(json['absent']) ?? 0,
      late: _asInt(json['late']) ?? 0,
      leave: _asInt(json['leave']) ?? 0,
      shortLeave: _asInt(json['short_leave']) ?? 0,
    );
  }
}

class TeacherAttendanceRecord {
  const TeacherAttendanceRecord({
    this.id,
    this.date,
    this.dateLabel,
    this.branchName,
    this.status,
    this.statusLabel,
    this.secondaryStatus,
    this.secondaryStatusLabel,
    this.inTimeLabel,
    this.outTimeLabel,
    this.remarks,
    this.markedBy,
  });

  final int? id;
  final String? date;
  final String? dateLabel;
  final String? branchName;
  final String? status;
  final String? statusLabel;
  final String? secondaryStatus;
  final String? secondaryStatusLabel;
  final String? inTimeLabel;
  final String? outTimeLabel;
  final String? remarks;
  final String? markedBy;

  String get displayDate => dateLabel?.trim().isNotEmpty == true ? dateLabel!.trim() : (date ?? '');

  String get displayBranch => branchName?.trim() ?? '';

  String get displayStatus {
    final label = statusLabel?.trim();
    if (label != null && label.isNotEmpty) return label;
    return _titleCase(status);
  }

  String get displayIn => _dash(inTimeLabel);
  String get displayOut => _dash(outTimeLabel);
  String get displayRemarks => _dash(remarks);
  String get displayMarkedBy => _dash(markedBy);

  factory TeacherAttendanceRecord.fromJson(Map<String, dynamic> json) {
    return TeacherAttendanceRecord(
      id: _asInt(json['id']),
      date: _asString(json['date']),
      dateLabel: _asString(json['date_label']),
      branchName: _asString(json['branch_name']),
      status: _asString(json['status']),
      statusLabel: _asString(json['status_label']),
      secondaryStatus: _asString(json['secondary_status']),
      secondaryStatusLabel: _asString(json['secondary_status_label']),
      inTimeLabel: _asString(json['in_time_label']),
      outTimeLabel: _asString(json['out_time_label']),
      remarks: _asString(json['remarks']),
      markedBy: _asString(json['marked_by']),
    );
  }
}

class TeacherAttendanceMeta {
  const TeacherAttendanceMeta({
    this.currentPage = 1,
    this.lastPage = 1,
    this.perPage = 25,
    this.total = 0,
    this.from,
    this.to,
  });

  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int? from;
  final int? to;

  bool get hasMore => currentPage < lastPage;

  factory TeacherAttendanceMeta.fromJson(Map<String, dynamic> json) {
    return TeacherAttendanceMeta(
      currentPage: _asInt(json['current_page']) ?? 1,
      lastPage: _asInt(json['last_page']) ?? 1,
      perPage: _asInt(json['per_page']) ?? 25,
      total: _asInt(json['total']) ?? 0,
      from: _asInt(json['from']),
      to: _asInt(json['to']),
    );
  }
}

class AttendanceStatusStyle {
  const AttendanceStatusStyle({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;

  static const present = AttendanceStatusStyle(
    background: Color(0xFFECFDF5),
    foreground: Color(0xFF047857),
  );
  static const absent = AttendanceStatusStyle(
    background: Color(0xFFFEF2F2),
    foreground: Color(0xFF991B1B),
  );
  static const late = AttendanceStatusStyle(
    background: Color(0xFFFFF7ED),
    foreground: Color(0xFFC2410C),
  );
  static const leave = AttendanceStatusStyle(
    background: Color(0xFFF5F3FF),
    foreground: Color(0xFF5B21B6),
  );
  static const shortLeave = AttendanceStatusStyle(
    background: Color(0xFFFDF2F8),
    foreground: Color(0xFFBE185D),
  );
  static const unmarked = AttendanceStatusStyle(
    background: Color(0xFFF1F5F9),
    foreground: Color(0xFF64748B),
  );

  static AttendanceStatusStyle of(String? status) {
    switch (status) {
      case 'present':
        return present;
      case 'absent':
        return absent;
      case 'late':
        return late;
      case 'leave':
        return leave;
      case 'short_leave':
        return shortLeave;
      default:
        return unmarked;
    }
  }
}

DateTime attendanceMonthStart(DateTime now) => DateTime(now.year, now.month, 1);

DateTime attendanceMonthEnd(DateTime now) => DateTime(now.year, now.month + 1, 0);

DateTime attendanceLastMonthStart(DateTime now) {
  return DateTime(now.year, now.month - 1, 1);
}

DateTime attendanceLastMonthEnd(DateTime now) {
  final start = attendanceLastMonthStart(now);
  return DateTime(start.year, start.month + 1, 0);
}

String isoAttendanceDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String displayAttendanceDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString().padLeft(4, '0');
  return '$day/$month/$year';
}

String attendanceMonthTitle(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[date.month - 1]} ${date.year}';
}

DateTime? parseAttendanceDate(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String? _asString(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  return value.toString();
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

List<T> _asObjectList<T>(
  dynamic value,
  T Function(Map<String, dynamic> json) map,
) {
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (_asMap(item) != null) map(_asMap(item)!),
  ];
}

String _dash(String? value) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? '—' : text;
}

String _titleCase(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return '—';
  return text
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');
}
