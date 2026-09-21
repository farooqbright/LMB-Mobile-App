class ParentSpecialRemarksData {
  const ParentSpecialRemarksData({
    this.studentName,
    this.className,
    this.sectionName,
    this.branchName,
    this.sessionName,
    this.rollNumber,
    this.period,
    this.date,
    this.dateFrom,
    this.dateTo,
    this.rangeLabel,
    this.hasEnrollment = true,
    this.remarksCount = 0,
    this.newCount = 0,
    this.remarks = const [],
    this.meta = const ParentRemarksPageMeta(),
  });

  final String? studentName;
  final String? className;
  final String? sectionName;
  final String? branchName;
  final String? sessionName;
  final String? rollNumber;
  final String? period;
  final String? date;
  final String? dateFrom;
  final String? dateTo;
  final String? rangeLabel;
  final bool hasEnrollment;
  final int remarksCount;
  final int newCount;
  final List<ParentSpecialRemark> remarks;
  final ParentRemarksPageMeta meta;

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

  String get headerSubtitle {
    return [
      if ((branchName ?? '').trim().isNotEmpty) branchName!.trim(),
      if ((sessionName ?? '').trim().isNotEmpty) sessionName!.trim(),
      if (classLabel.isNotEmpty) classLabel,
      if ((rollNumber ?? '').trim().isNotEmpty) 'Roll ${rollNumber!.trim()}',
    ].join(' · ');
  }

  bool get hasMore => meta.hasMore;

  ParentSpecialRemarksData mergePage(ParentSpecialRemarksData next) {
    return ParentSpecialRemarksData(
      studentName: next.studentName ?? studentName,
      className: next.className ?? className,
      sectionName: next.sectionName ?? sectionName,
      branchName: next.branchName ?? branchName,
      sessionName: next.sessionName ?? sessionName,
      rollNumber: next.rollNumber ?? rollNumber,
      period: next.period ?? period,
      date: next.date ?? date,
      dateFrom: next.dateFrom ?? dateFrom,
      dateTo: next.dateTo ?? dateTo,
      rangeLabel: next.rangeLabel ?? rangeLabel,
      hasEnrollment: next.hasEnrollment,
      remarksCount: next.remarksCount,
      newCount: next.newCount,
      remarks: _mergeById(remarks, next.remarks, (row) => row.id),
      meta: next.meta,
    );
  }

  factory ParentSpecialRemarksData.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? metaJson,
  }) {
    final student = _asMap(json['student']) ?? const <String, dynamic>{};
    return ParentSpecialRemarksData(
      studentName: _asString(student['full_name']) ?? _asString(json['student_name']),
      className: _asString(student['class_name']),
      sectionName: _asString(student['section_name']),
      branchName: _asString(student['branch_name']),
      sessionName: _asString(student['session_name']),
      rollNumber: _asString(student['roll_number']),
      period: _asString(json['period']),
      date: _asString(json['date']),
      dateFrom: _asString(json['date_from']),
      dateTo: _asString(json['date_to']),
      rangeLabel: _asString(json['range_label']),
      hasEnrollment: json['has_enrollment'] != false,
      remarksCount: _asInt(json['remarks_count']) ?? 0,
      newCount: _asInt(json['new_count']) ?? 0,
      remarks: _asObjectList(json['remarks'], ParentSpecialRemark.fromJson),
      meta: ParentRemarksPageMeta.fromJson(metaJson ?? _asMap(json['meta']) ?? const {}),
    );
  }
}

class ParentSpecialRemark {
  const ParentSpecialRemark({
    this.id,
    this.remarkDate,
    this.dateLabel,
    this.weekday,
    this.remarks,
    this.teacherName,
    this.isNew = false,
  });

  final int? id;
  final String? remarkDate;
  final String? dateLabel;
  final String? weekday;
  final String? remarks;
  final String? teacherName;
  final bool isNew;

  String get displayDate {
    if ((dateLabel ?? '').trim().isNotEmpty) return dateLabel!.trim();
    return remarkDate ?? '';
  }

  factory ParentSpecialRemark.fromJson(Map<String, dynamic> json) {
    return ParentSpecialRemark(
      id: _asInt(json['id']),
      remarkDate: _asString(json['remark_date']),
      dateLabel: _asString(json['date_label']),
      weekday: _asString(json['weekday']),
      remarks: _asString(json['remarks']),
      teacherName: _asString(json['teacher_name']),
      isNew: json['is_new'] == true,
    );
  }
}

class ParentRemarksPageMeta {
  const ParentRemarksPageMeta({
    this.currentPage = 1,
    this.lastPage = 1,
    this.perPage = 25,
    this.total = 0,
  });

  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  bool get hasMore => currentPage < lastPage;

  factory ParentRemarksPageMeta.fromJson(Map<String, dynamic> json) {
    return ParentRemarksPageMeta(
      currentPage: _asInt(json['current_page']) ?? 1,
      lastPage: _asInt(json['last_page']) ?? 1,
      perPage: _asInt(json['per_page']) ?? 25,
      total: _asInt(json['total']) ?? 0,
    );
  }
}

List<T> _mergeById<T>(
  List<T> current,
  List<T> next,
  int? Function(T row) idOf,
) {
  final seen = <int>{};
  final merged = <T>[];
  for (final row in [...current, ...next]) {
    final id = idOf(row);
    if (id != null) {
      if (seen.contains(id)) continue;
      seen.add(id);
    }
    merged.add(row);
  }
  return merged;
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
