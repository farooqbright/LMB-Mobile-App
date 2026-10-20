class ParentCurriculumSubjects {
  const ParentCurriculumSubjects({
    this.studentName,
    this.className,
    this.sectionName,
    this.branchName,
    this.sessionName,
    this.hasEnrollment = true,
    this.subjects = const [],
  });

  final String? studentName;
  final String? className;
  final String? sectionName;
  final String? branchName;
  final String? sessionName;
  final bool hasEnrollment;
  final List<ParentCurriculumSubject> subjects;

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

  bool get isEmpty => subjects.isEmpty;

  factory ParentCurriculumSubjects.fromJson(Map<String, dynamic> json) {
    final student = _asMap(json['student']) ?? const <String, dynamic>{};
    final klass = _asMap(json['class']) ?? const <String, dynamic>{};

    return ParentCurriculumSubjects(
      studentName:
          _asString(student['full_name']) ?? _asString(json['student_name']),
      className: _asString(klass['name']) ??
          _asString(student['class_name']) ??
          _asString(json['class_name']),
      sectionName: _asString(klass['section_name']) ??
          _asString(student['section_name']) ??
          _asString(json['section_name']),
      branchName:
          _asString(student['branch_name']) ?? _asString(json['branch_name']),
      sessionName: _asString(klass['session_name']) ??
          _asString(json['session_name']),
      hasEnrollment: json['has_enrollment'] != false,
      subjects: _asObjectList(json['subjects'], ParentCurriculumSubject.fromJson),
    );
  }
}

class ParentCurriculumSubject {
  const ParentCurriculumSubject({
    required this.subjectId,
    this.subjectName,
    this.hasPlan = false,
    this.planId,
    this.total = 0,
    this.completed = 0,
    this.pending = 0,
    this.progressPercent = 0,
  });

  final int subjectId;
  final String? subjectName;
  final bool hasPlan;
  final int? planId;
  final int total;
  final int completed;
  final int pending;
  final int progressPercent;

  String get title =>
      (subjectName ?? '').trim().isNotEmpty ? subjectName!.trim() : 'Subject';

  String get progressLine {
    if (total < 1) return '';
    return '$completed completed · $pending pending · $progressPercent%';
  }

  factory ParentCurriculumSubject.fromJson(Map<String, dynamic> json) {
    return ParentCurriculumSubject(
      subjectId: _asInt(json['subject_id']) ?? 0,
      subjectName: _asString(json['subject_name']),
      hasPlan: _asBool(json['has_plan']) || _asBool(json['has_published_plan']),
      planId: _asInt(json['plan_id']),
      total: _asInt(json['total']) ?? 0,
      completed: _asInt(json['completed']) ?? 0,
      pending: _asInt(json['pending']) ?? 0,
      progressPercent: _asInt(json['progress_percent']) ?? 0,
    );
  }
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final text = value.trim().toLowerCase();
    return text == '1' || text == 'true' || text == 'yes';
  }
  return false;
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
  if (value is List) {
    return [
      for (final item in value)
        if (_asMap(item) != null) map(_asMap(item)!),
    ];
  }
  final object = _asMap(value);
  if (object == null) return const [];
  return [
    for (final item in object.values)
      if (_asMap(item) != null) map(_asMap(item)!),
  ];
}
