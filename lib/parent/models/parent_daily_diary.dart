class ParentDailyDiaryData {
  const ParentDailyDiaryData({
    this.studentName,
    this.className,
    this.sectionName,
    this.branchName,
    this.period,
    this.date,
    this.dateFrom,
    this.dateTo,
    this.rangeLabel,
    this.hasEnrollment = true,
    this.daysCount = 0,
    this.subjectsCount = 0,
    this.days = const [],
  });

  final String? studentName;
  final String? className;
  final String? sectionName;
  final String? branchName;
  final String? period;
  final String? date;
  final String? dateFrom;
  final String? dateTo;
  final String? rangeLabel;
  final bool hasEnrollment;
  final int daysCount;
  final int subjectsCount;
  final List<ParentDiaryDay> days;

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

  bool get isEmpty => days.every((day) => day.entries.isEmpty);

  factory ParentDailyDiaryData.fromJson(Map<String, dynamic> json) {
    final student = _asMap(json['student']) ?? const <String, dynamic>{};

    return ParentDailyDiaryData(
      studentName: _asString(student['full_name']) ?? _asString(json['student_name']),
      className: _asString(student['class_name']),
      sectionName: _asString(student['section_name']),
      branchName: _asString(student['branch_name']),
      period: _asString(json['period']),
      date: _asString(json['date']),
      dateFrom: _asString(json['date_from']),
      dateTo: _asString(json['date_to']),
      rangeLabel: _asString(json['range_label']),
      hasEnrollment: json['has_enrollment'] != false,
      daysCount: _asInt(json['days_count']) ?? 0,
      subjectsCount: _asInt(json['subjects_count']) ?? 0,
      days: _asObjectList(json['days'], ParentDiaryDay.fromJson),
    );
  }
}

class ParentDiaryDay {
  const ParentDiaryDay({
    this.date,
    this.dateLabel,
    this.weekday,
    this.entries = const [],
  });

  final String? date;
  final String? dateLabel;
  final String? weekday;
  final List<ParentDiaryEntry> entries;

  String get displayDate =>
      dateLabel?.trim().isNotEmpty == true ? dateLabel!.trim() : (date ?? '');

  factory ParentDiaryDay.fromJson(Map<String, dynamic> json) {
    return ParentDiaryDay(
      date: _asString(json['date']),
      dateLabel: _asString(json['date_label']),
      weekday: _asString(json['weekday']),
      entries: _asObjectList(json['entries'], ParentDiaryEntry.fromJson),
    );
  }
}

class ParentDiaryEntry {
  const ParentDiaryEntry({
    this.id,
    this.subjectId,
    this.subjectName,
    this.workDone,
    this.homework,
    this.remarks,
    this.teacherName,
  });

  final int? id;
  final int? subjectId;
  final String? subjectName;
  final String? workDone;
  final String? homework;
  final String? remarks;
  final String? teacherName;

  String get displaySubject {
    final name = subjectName?.trim();
    return (name == null || name.isEmpty) ? '—' : name;
  }

  String get displayWorkDone => _dash(workDone);

  String get displayHomework => _dash(homework);

  factory ParentDiaryEntry.fromJson(Map<String, dynamic> json) {
    return ParentDiaryEntry(
      id: _asInt(json['id']),
      subjectId: _asInt(json['subject_id']),
      subjectName: _asString(json['subject_name']),
      workDone: _asString(json['work_done']),
      homework: _asString(json['homework']),
      remarks: _asString(json['remarks']),
      teacherName: _asString(json['teacher_name']),
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

String _dash(String? value) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? '—' : text;
}
