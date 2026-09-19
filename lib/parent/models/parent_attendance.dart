import '../../models/teacher_attendance.dart';

class ParentAttendanceData {
  const ParentAttendanceData({
    this.studentName,
    this.className,
    this.sectionName,
    this.branchName,
    this.monthLabel,
    this.lastMonthLabel,
    this.statuses = const [],
    this.summary = const ParentAttendanceSummary(),
    this.records = const [],
    this.meta = const ParentAttendanceMeta(),
  });

  final String? studentName;
  final String? className;
  final String? sectionName;
  final String? branchName;
  final String? monthLabel;
  final String? lastMonthLabel;
  final List<AttendanceStatusOption> statuses;
  final ParentAttendanceSummary summary;
  final List<ParentAttendanceRecord> records;
  final ParentAttendanceMeta meta;

  String get classLabel {
    final klass = className?.trim();
    final section = sectionName?.trim();
    if (klass != null && klass.isNotEmpty && section != null && section.isNotEmpty) {
      return '$klass - $section';
    }
    if (klass != null && klass.isNotEmpty) return klass;
    if (section != null && section.isNotEmpty) return section;
    return '';
  }

  bool get isEmpty => records.isEmpty;

  bool get hasMore => meta.hasMore;

  ParentAttendanceData mergePage(ParentAttendanceData next) {
    final seen = <int>{
      for (final record in records)
        if (record.id != null) record.id!,
    };

    return ParentAttendanceData(
      studentName: studentName ?? next.studentName,
      className: className ?? next.className,
      sectionName: sectionName ?? next.sectionName,
      branchName: branchName ?? next.branchName,
      monthLabel: monthLabel ?? next.monthLabel,
      lastMonthLabel: lastMonthLabel ?? next.lastMonthLabel,
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

  factory ParentAttendanceData.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? metaJson,
  }) {
    final student = _asMap(json['student']) ?? const <String, dynamic>{};

    return ParentAttendanceData(
      studentName: _asString(student['full_name']) ?? _asString(json['student_name']),
      className: _asString(student['class_name']),
      sectionName: _asString(student['section_name']),
      branchName: _asString(student['branch_name']),
      monthLabel: _asString(json['month_label']),
      lastMonthLabel: _asString(json['last_month_label']),
      statuses: _asObjectList(json['statuses'], AttendanceStatusOption.fromJson),
      summary: ParentAttendanceSummary.fromJson(_asMap(json['summary']) ?? const {}),
      records: _asObjectList(json['records'], ParentAttendanceRecord.fromJson),
      meta: ParentAttendanceMeta.fromJson(
        metaJson ?? _asMap(json['meta']) ?? const {},
      ),
    );
  }
}

class ParentAttendanceSummary {
  const ParentAttendanceSummary({
    this.today,
    this.month = const AttendanceMonthCounts(),
    this.lastMonth = const AttendanceMonthCounts(),
  });

  final AttendanceToday? today;
  final AttendanceMonthCounts month;
  final AttendanceMonthCounts lastMonth;

  factory ParentAttendanceSummary.fromJson(Map<String, dynamic> json) {
    final todayJson = _asMap(json['today']);
    final month = AttendanceMonthCounts.fromJson(_asMap(json['month']) ?? const {});
    return ParentAttendanceSummary(
      today: todayJson == null ? null : AttendanceToday.fromJson(todayJson),
      month: month,
      lastMonth: AttendanceMonthCounts.fromJson(
        _asMap(json['last_month']) ?? _asMap(json['month']) ?? const {},
      ),
    );
  }
}

class ParentAttendanceRecord {
  const ParentAttendanceRecord({
    this.id,
    this.date,
    this.dateLabel,
    this.status,
    this.statusLabel,
    this.remarks,
    this.markedBy,
  });

  final int? id;
  final String? date;
  final String? dateLabel;
  final String? status;
  final String? statusLabel;
  final String? remarks;
  final String? markedBy;

  String get displayDate =>
      dateLabel?.trim().isNotEmpty == true ? dateLabel!.trim() : (date ?? '');

  String get displayStatus {
    final label = statusLabel?.trim();
    if (label != null && label.isNotEmpty) return label;
    return _titleCase(status);
  }

  String get displayRemarks {
    final text = remarks?.trim() ?? '';
    return text.isEmpty ? '—' : text;
  }

  factory ParentAttendanceRecord.fromJson(Map<String, dynamic> json) {
    return ParentAttendanceRecord(
      id: _asInt(json['id']),
      date: _asString(json['date']),
      dateLabel: _asString(json['date_label']),
      status: _asString(json['status']),
      statusLabel: _asString(json['status_label']),
      remarks: _asString(json['remarks']),
      markedBy: _asString(json['marked_by']),
    );
  }
}

class ParentAttendanceMeta {
  const ParentAttendanceMeta({
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

  factory ParentAttendanceMeta.fromJson(Map<String, dynamic> json) {
    return ParentAttendanceMeta(
      currentPage: _asInt(json['current_page']) ?? 1,
      lastPage: _asInt(json['last_page']) ?? 1,
      perPage: _asInt(json['per_page']) ?? 25,
      total: _asInt(json['total']) ?? 0,
      from: _asInt(json['from']),
      to: _asInt(json['to']),
    );
  }
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

String _titleCase(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return '—';
  return text
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');
}
