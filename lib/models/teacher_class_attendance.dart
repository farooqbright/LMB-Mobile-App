class TeacherClassAttendanceClasses {
  const TeacherClassAttendanceClasses({
    this.teacherName,
    this.date,
    this.summary = const ClassAttendanceSummary(),
    this.classes = const [],
  });

  final String? teacherName;
  final String? date;
  final ClassAttendanceSummary summary;
  final List<ClassAttendanceClass> classes;

  bool get isEmpty => classes.isEmpty;

  factory TeacherClassAttendanceClasses.fromJson(Map<String, dynamic> json) {
    return TeacherClassAttendanceClasses(
      teacherName: _asString(_asMap(json['teacher'])?['full_name']),
      date: _asString(json['date']),
      summary: ClassAttendanceSummary.fromJson(_asMap(json['summary']) ?? const {}),
      classes: _asObjectList(json['classes'], ClassAttendanceClass.fromJson),
    );
  }
}

class ClassAttendanceSummary {
  const ClassAttendanceSummary({
    this.total = 0,
    this.marked = 0,
    this.unmarked = 0,
    this.present = 0,
    this.absent = 0,
    this.late = 0,
    this.leave = 0,
  });

  final int total;
  final int marked;
  final int unmarked;
  final int present;
  final int absent;
  final int late;
  final int leave;

  factory ClassAttendanceSummary.fromJson(Map<String, dynamic> json) {
    return ClassAttendanceSummary(
      total: _asInt(json['total']) ?? 0,
      marked: _asInt(json['marked']) ?? 0,
      unmarked: _asInt(json['unmarked']) ?? 0,
      present: _asInt(json['present']) ?? 0,
      absent: _asInt(json['absent']) ?? 0,
      late: _asInt(json['late']) ?? 0,
      leave: _asInt(json['leave']) ?? 0,
    );
  }
}

class ClassAttendanceClass {
  const ClassAttendanceClass({
    required this.academicSessionId,
    required this.classId,
    this.sessionName,
    this.className,
    this.sections = const [],
  });

  final int academicSessionId;
  final int classId;
  final String? sessionName;
  final String? className;
  final List<ClassAttendanceSection> sections;

  String get title => (className ?? '').trim().isNotEmpty ? className!.trim() : 'Class';

  String get sessionLabel => (sessionName ?? '').trim();

  factory ClassAttendanceClass.fromJson(Map<String, dynamic> json) {
    return ClassAttendanceClass(
      academicSessionId: _asInt(json['academic_session_id']) ?? 0,
      classId: _asInt(json['class_id']) ?? 0,
      sessionName: _asString(json['session_name']),
      className: _asString(json['class_name']),
      sections: _asObjectList(json['sections'], ClassAttendanceSection.fromJson),
    );
  }
}

class ClassAttendanceSection {
  const ClassAttendanceSection({
    required this.classSectionId,
    this.sectionName,
    this.total = 0,
    this.marked = 0,
    this.unmarked = 0,
    this.present = 0,
    this.absent = 0,
    this.late = 0,
    this.leave = 0,
    this.action,
  });

  final int classSectionId;
  final String? sectionName;
  final int total;
  final int marked;
  final int unmarked;
  final int present;
  final int absent;
  final int late;
  final int leave;
  final String? action;

  String get title => (sectionName ?? '').trim().isNotEmpty ? sectionName!.trim() : 'Section';

  String get displayName {
    final name = title;
    if (name.toLowerCase().startsWith('section')) return name;
    return 'Section $name';
  }

  String get actionLabel => (action ?? '').trim().isNotEmpty ? action!.trim() : (marked > 0 ? 'Update' : 'Mark');

  factory ClassAttendanceSection.fromJson(Map<String, dynamic> json) {
    return ClassAttendanceSection(
      classSectionId: _asInt(json['class_section_id']) ?? 0,
      sectionName: _asString(json['section_name']),
      total: _asInt(json['total']) ?? 0,
      marked: _asInt(json['marked']) ?? 0,
      unmarked: _asInt(json['unmarked']) ?? 0,
      present: _asInt(json['present']) ?? 0,
      absent: _asInt(json['absent']) ?? 0,
      late: _asInt(json['late']) ?? 0,
      leave: _asInt(json['leave']) ?? 0,
      action: _asString(json['action']),
    );
  }
}

class TeacherClassAttendanceMark {
  const TeacherClassAttendanceMark({
    required this.date,
    this.canMark = true,
    this.blockMessage,
    this.sessionName,
    this.className,
    this.sectionName,
    this.alreadyMarked = false,
    this.statuses = const [],
    this.students = const [],
  });

  final String date;
  final bool canMark;
  final String? blockMessage;
  final String? sessionName;
  final String? className;
  final String? sectionName;
  final bool alreadyMarked;
  final List<ClassAttendanceStatusOption> statuses;
  final List<ClassAttendanceStudent> students;

  String get heading {
    final classTitle = (className ?? '').trim();
    final sectionTitle = (sectionName ?? '').trim();
    if (classTitle.isEmpty) return 'Mark Attendance';
    if (sectionTitle.isEmpty) return classTitle;
    return '$classTitle — $sectionTitle';
  }

  factory TeacherClassAttendanceMark.fromJson(Map<String, dynamic> json) {
    final classJson = _asMap(json['class']) ?? const {};
    return TeacherClassAttendanceMark(
      date: _asString(json['date']) ?? '',
      canMark: json['can_mark'] != false,
      blockMessage: _asString(json['block_message']),
      sessionName: _asString(classJson['session_name']),
      className: _asString(classJson['class_name']),
      sectionName: _asString(classJson['section_name']),
      alreadyMarked: json['already_marked'] == true,
      statuses: _asObjectList(json['statuses'], ClassAttendanceStatusOption.fromJson),
      students: _asObjectList(json['students'], ClassAttendanceStudent.fromJson),
    );
  }

  TeacherClassAttendanceMark copyWithStudents(List<ClassAttendanceStudent> students) {
    return TeacherClassAttendanceMark(
      date: date,
      canMark: canMark,
      blockMessage: blockMessage,
      sessionName: sessionName,
      className: className,
      sectionName: sectionName,
      alreadyMarked: alreadyMarked,
      statuses: statuses,
      students: students,
    );
  }
}

class ClassAttendanceStatusOption {
  const ClassAttendanceStatusOption({required this.key, required this.label});

  final String key;
  final String label;

  factory ClassAttendanceStatusOption.fromJson(Map<String, dynamic> json) {
    return ClassAttendanceStatusOption(
      key: _asString(json['key']) ?? '',
      label: _asString(json['label']) ?? '',
    );
  }
}

class ClassAttendanceStudent {
  const ClassAttendanceStudent({
    required this.id,
    this.fullName,
    this.rollNumber,
    this.fatherName,
    this.photoUrl,
    this.status = 'present',
    this.alreadyMarked = false,
    this.locked = false,
    this.remarks,
  });

  final int id;
  final String? fullName;
  final String? rollNumber;
  final String? fatherName;
  final String? photoUrl;
  final String status;
  final bool alreadyMarked;
  final bool locked;
  final String? remarks;

  String get displayName => (fullName ?? '').trim().isNotEmpty ? fullName!.trim() : 'Student';

  String get displayRoll => (rollNumber ?? '').trim();

  String get initials {
    final parts = displayName.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'S';
    return parts.first.substring(0, 1).toUpperCase();
  }

  ClassAttendanceStudent copyWithStatus(String status) {
    return ClassAttendanceStudent(
      id: id,
      fullName: fullName,
      rollNumber: rollNumber,
      fatherName: fatherName,
      photoUrl: photoUrl,
      status: status,
      alreadyMarked: alreadyMarked,
      locked: locked,
      remarks: remarks,
    );
  }

  factory ClassAttendanceStudent.fromJson(Map<String, dynamic> json) {
    return ClassAttendanceStudent(
      id: _asInt(json['id']) ?? 0,
      fullName: _asString(json['full_name']),
      rollNumber: _asString(json['roll_number']),
      fatherName: _asString(json['father_name']),
      photoUrl: _asString(json['photo_url']),
      status: _asString(json['status']) ?? 'present',
      alreadyMarked: json['already_marked'] == true,
      locked: json['locked'] == true,
      remarks: _asString(json['remarks']),
    );
  }
}

class TeacherClassAttendanceSaveResult {
  const TeacherClassAttendanceSaveResult({this.saved = 0, this.message});

  final int saved;
  final String? message;
}

String isoClassAttendanceDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String displayClassAttendanceDate(String iso) {
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return iso;
  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  return '$day/$month/${parsed.year}';
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
