import '../../models/teacher_timetable.dart';

class ParentTimetableData {
  const ParentTimetableData({
    this.studentName,
    this.className,
    this.sectionName,
    this.branchName,
    this.hasEnrollment = true,
    this.schedule,
  });

  final String? studentName;
  final String? className;
  final String? sectionName;
  final String? branchName;
  final bool hasEnrollment;
  final TeacherSchedule? schedule;

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

  bool get isEmpty => schedule == null;

  factory ParentTimetableData.fromJson(Map<String, dynamic> json) {
    final student = _asMap(json['student']) ?? const <String, dynamic>{};
    final scheduleJson = _asMap(json['schedule']);

    return ParentTimetableData(
      studentName: _asString(student['full_name']) ?? _asString(json['student_name']),
      className: _asString(student['class_name']),
      sectionName: _asString(student['section_name']),
      branchName: _asString(student['branch_name']),
      hasEnrollment: json['has_enrollment'] != false,
      schedule: scheduleJson == null ? null : TeacherSchedule.fromJson(scheduleJson),
    );
  }
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
