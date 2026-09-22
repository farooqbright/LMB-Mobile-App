class TeacherSpecialRemarksData {
  const TeacherSpecialRemarksData({
    required this.classItem,
    this.date,
    this.dateLabel,
    this.studentsCount = 0,
    this.withRemarksCount = 0,
    this.students = const [],
  });

  final TeacherSpecialRemarksClass classItem;
  final String? date;
  final String? dateLabel;
  final int studentsCount;
  final int withRemarksCount;
  final List<TeacherSpecialRemarkStudent> students;

  String get heading {
    final klass = classItem.className?.trim();
    final section = classItem.sectionName?.trim();
    if (klass != null && klass.isNotEmpty && section != null && section.isNotEmpty) {
      return '$klass — $section — Special Remarks';
    }
    if (klass != null && klass.isNotEmpty) {
      return '$klass — Special Remarks';
    }
    return 'Special Remarks';
  }

  String get subtitle {
    return [
      if ((classItem.sessionName ?? '').trim().isNotEmpty) classItem.sessionName!.trim(),
      if ((dateLabel ?? '').trim().isNotEmpty) dateLabel!.trim(),
      '$studentsCount student${studentsCount == 1 ? '' : 's'}',
      '$withRemarksCount with remarks',
      'each save adds a new remark (form stays empty)',
    ].join(' · ');
  }

  factory TeacherSpecialRemarksData.fromJson(Map<String, dynamic> json) {
    final classJson = _asMap(json['class']) ?? const {};
    return TeacherSpecialRemarksData(
      classItem: TeacherSpecialRemarksClass.fromJson(classJson),
      date: _asString(json['date']),
      dateLabel: _asString(json['date_label']),
      studentsCount: _asInt(json['students_count']) ?? 0,
      withRemarksCount: _asInt(json['with_remarks_count']) ?? 0,
      students: _asObjectList(json['students'], TeacherSpecialRemarkStudent.fromJson),
    );
  }
}

class TeacherSpecialRemarksClass {
  const TeacherSpecialRemarksClass({
    required this.academicSessionId,
    required this.classId,
    required this.classSectionId,
    this.sessionName,
    this.className,
    this.sectionName,
  });

  final int academicSessionId;
  final int classId;
  final int classSectionId;
  final String? sessionName;
  final String? className;
  final String? sectionName;

  factory TeacherSpecialRemarksClass.fromJson(Map<String, dynamic> json) {
    return TeacherSpecialRemarksClass(
      academicSessionId: _asInt(json['academic_session_id']) ?? 0,
      classId: _asInt(json['class_id']) ?? 0,
      classSectionId: _asInt(json['class_section_id']) ?? 0,
      sessionName: _asString(json['session_name']),
      className: _asString(json['class_name']),
      sectionName: _asString(json['section_name']),
    );
  }
}

class TeacherSpecialRemarkStudent {
  const TeacherSpecialRemarkStudent({
    required this.id,
    this.fullName,
    this.rollNumber,
    this.classSectionId,
    this.sectionName,
    this.remarks,
    this.hasRemark = false,
    this.remarksCount = 0,
    this.todayRemarks = const [],
  });

  final int id;
  final String? fullName;
  final String? rollNumber;
  final int? classSectionId;
  final String? sectionName;
  final String? remarks;
  final bool hasRemark;
  final int remarksCount;
  final List<TeacherPriorRemark> todayRemarks;

  String get title {
    final name = (fullName ?? '').trim();
    return name.isEmpty ? 'Student' : name;
  }

  String get subtitle {
    return [
      if ((rollNumber ?? '').trim().isNotEmpty) 'Roll ${rollNumber!.trim()}',
      if ((sectionName ?? '').trim().isNotEmpty) 'Section ${sectionName!.trim()}',
      if (remarksCount > 0)
        '$remarksCount earlier today',
    ].join(' · ');
  }

  factory TeacherSpecialRemarkStudent.fromJson(Map<String, dynamic> json) {
    final remarks = _asString(json['remarks']);
    final todayRemarks = _asObjectList(json['today_remarks'], TeacherPriorRemark.fromJson);
    final remarksCount = _asInt(json['remarks_count']) ?? todayRemarks.length;
    return TeacherSpecialRemarkStudent(
      id: _asInt(json['id']) ?? 0,
      fullName: _asString(json['full_name']),
      rollNumber: _asString(json['roll_number']),
      classSectionId: _asInt(json['class_section_id']),
      sectionName: _asString(json['section_name']),
      remarks: remarks,
      hasRemark: json['has_remark'] == true || remarksCount > 0,
      remarksCount: remarksCount,
      todayRemarks: todayRemarks,
    );
  }
}

class TeacherPriorRemark {
  const TeacherPriorRemark({
    this.id,
    this.text,
    this.teacherName,
    this.createdAt,
    this.timeLabel,
  });

  final int? id;
  final String? text;
  final String? teacherName;
  final String? createdAt;
  final String? timeLabel;

  String get displayTime {
    if ((timeLabel ?? '').trim().isNotEmpty) return timeLabel!.trim();
    final parsed = DateTime.tryParse(createdAt ?? '');
    if (parsed == null) return '';
    final local = parsed.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String get meta {
    return [
      if ((teacherName ?? '').trim().isNotEmpty) teacherName!.trim() else 'Teacher',
      if (displayTime.isNotEmpty) displayTime,
    ].join(' · ');
  }

  factory TeacherPriorRemark.fromJson(Map<String, dynamic> json) {
    return TeacherPriorRemark(
      id: _asInt(json['id']),
      text: _asString(json['text'] ?? json['remarks']),
      teacherName: _asString(json['teacher_name']),
      createdAt: _asString(json['created_at']),
      timeLabel: _asString(json['time_label']),
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
