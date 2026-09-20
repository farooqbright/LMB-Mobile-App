class TeacherExamList {
  const TeacherExamList({
    this.teacherName,
    this.session,
    this.sessions = const [],
    this.exams = const [],
    this.meta = const TeacherExamPageMeta(),
  });

  final String? teacherName;
  final TeacherExamSession? session;
  final List<TeacherExamSession> sessions;
  final List<TeacherExamSummary> exams;
  final TeacherExamPageMeta meta;

  bool get isEmpty => exams.isEmpty;

  bool get hasMore => meta.hasMore;

  TeacherExamList mergePage(TeacherExamList next) {
    final seen = <int>{for (final exam in exams) exam.id};
    return TeacherExamList(
      teacherName: teacherName ?? next.teacherName,
      session: session ?? next.session,
      sessions: sessions.isNotEmpty ? sessions : next.sessions,
      exams: [
        ...exams,
        for (final exam in next.exams)
          if (seen.add(exam.id)) exam,
      ],
      meta: next.meta,
    );
  }

  factory TeacherExamList.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? metaJson,
  }) {
    return TeacherExamList(
      teacherName: _asString(_asMap(json['teacher'])?['full_name']),
      session: json['session'] is Map
          ? TeacherExamSession.fromJson(_asMap(json['session']) ?? const {})
          : null,
      sessions: _asObjectList(json['sessions'], TeacherExamSession.fromJson),
      exams: _asObjectList(json['exams'], TeacherExamSummary.fromJson),
      meta: TeacherExamPageMeta.fromJson(metaJson ?? _asMap(json['meta']) ?? const {}),
    );
  }
}

class TeacherExamPageMeta {
  const TeacherExamPageMeta({
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

  factory TeacherExamPageMeta.fromJson(Map<String, dynamic> json) {
    return TeacherExamPageMeta(
      currentPage: _asInt(json['current_page']) ?? 1,
      lastPage: _asInt(json['last_page']) ?? 1,
      perPage: _asInt(json['per_page']) ?? 25,
      total: _asInt(json['total']) ?? 0,
    );
  }
}

class TeacherExamSession {
  const TeacherExamSession({
    required this.id,
    this.name,
    this.status,
  });

  final int id;
  final String? name;
  final String? status;

  String get title => (name ?? '').trim().isNotEmpty ? name!.trim() : 'Session';

  factory TeacherExamSession.fromJson(Map<String, dynamic> json) {
    return TeacherExamSession(
      id: _asInt(json['id']) ?? 0,
      name: _asString(json['name']),
      status: _asString(json['status']),
    );
  }
}

class TeacherExamSummary {
  const TeacherExamSummary({
    required this.id,
    this.name,
    this.status,
    this.statusLabel,
    this.academicSessionId,
    this.sessionName,
    this.startDate,
    this.endDate,
    this.datesheetCount = 0,
    this.markableCount = 0,
    this.datesheets = const [],
  });

  final int id;
  final String? name;
  final String? status;
  final String? statusLabel;
  final int? academicSessionId;
  final String? sessionName;
  final String? startDate;
  final String? endDate;
  final int datesheetCount;
  final int markableCount;
  final List<TeacherExamDatesheet> datesheets;

  String get title => (name ?? '').trim().isNotEmpty ? name!.trim() : 'Exam';

  String get statusText =>
      (statusLabel ?? status ?? '').trim().isNotEmpty
          ? (statusLabel ?? status)!.trim()
          : 'Draft';

  String get dateRange {
    final start = displayExamDate(startDate);
    final end = displayExamDate(endDate);
    if (start.isEmpty && end.isEmpty) return '';
    if (start.isEmpty) return end;
    if (end.isEmpty || start == end) return start;
    return '$start – $end';
  }

  factory TeacherExamSummary.fromJson(Map<String, dynamic> json) {
    return TeacherExamSummary(
      id: _asInt(json['id']) ?? 0,
      name: _asString(json['name']),
      status: _asString(json['status']),
      statusLabel: _asString(json['status_label']),
      academicSessionId: _asInt(json['academic_session_id']),
      sessionName: _asString(json['session_name']),
      startDate: _asString(json['start_date']),
      endDate: _asString(json['end_date']),
      datesheetCount: _asInt(json['datesheet_count']) ?? 0,
      markableCount: _asInt(json['markable_count']) ?? 0,
      datesheets: _asObjectList(json['datesheets'], TeacherExamDatesheet.fromJson),
    );
  }
}

class TeacherExamDatesheet {
  const TeacherExamDatesheet({
    required this.id,
    this.name,
    this.subjectCount = 0,
    this.classes = const [],
  });

  final int id;
  final String? name;
  final int subjectCount;
  final List<TeacherExamClass> classes;

  String get title => (name ?? '').trim().isNotEmpty ? name!.trim() : 'Datesheet';

  factory TeacherExamDatesheet.fromJson(Map<String, dynamic> json) {
    return TeacherExamDatesheet(
      id: _asInt(json['id']) ?? 0,
      name: _asString(json['name']),
      subjectCount: _asInt(json['subject_count']) ?? 0,
      classes: _asObjectList(json['classes'], TeacherExamClass.fromJson),
    );
  }
}

class TeacherExamClass {
  const TeacherExamClass({
    required this.classId,
    this.className,
    this.sections = const [],
  });

  final int classId;
  final String? className;
  final List<TeacherExamSection> sections;

  String get title => (className ?? '').trim().isNotEmpty ? className!.trim() : 'Class';

  factory TeacherExamClass.fromJson(Map<String, dynamic> json) {
    return TeacherExamClass(
      classId: _asInt(json['class_id']) ?? 0,
      className: _asString(json['class_name']),
      sections: _asObjectList(json['sections'], TeacherExamSection.fromJson),
    );
  }
}

class TeacherExamSection {
  const TeacherExamSection({
    required this.classSectionId,
    this.sectionName,
    this.subjectCount = 0,
  });

  final int classSectionId;
  final String? sectionName;
  final int subjectCount;

  String get displayName {
    final name = (sectionName ?? '').trim();
    if (name.isEmpty) return 'Section';
    final lower = name.toLowerCase();
    if (lower.startsWith('section ')) return name;
    return 'Section $name';
  }

  factory TeacherExamSection.fromJson(Map<String, dynamic> json) {
    return TeacherExamSection(
      classSectionId: _asInt(json['class_section_id']) ?? 0,
      sectionName: _asString(json['section_name']),
      subjectCount: _asInt(json['subject_count']) ?? 0,
    );
  }
}

class TeacherExamMarksGrid {
  const TeacherExamMarksGrid({
    this.examName,
    this.sessionName,
    this.datesheetName,
    this.className,
    this.sectionName,
    this.subjects = const [],
    this.students = const [],
  });

  final String? examName;
  final String? sessionName;
  final String? datesheetName;
  final String? className;
  final String? sectionName;
  final List<TeacherExamSubject> subjects;
  final List<TeacherExamStudent> students;

  String get heading {
    final classTitle = (className ?? '').trim().isNotEmpty ? className!.trim() : 'Class';
    final sectionTitle = (sectionName ?? '').trim();
    if (sectionTitle.isEmpty) return classTitle;
    return '$classTitle — $sectionTitle';
  }

  factory TeacherExamMarksGrid.fromJson(Map<String, dynamic> json) {
    final exam = _asMap(json['exam']) ?? const <String, dynamic>{};
    final datesheet = _asMap(json['datesheet']) ?? const <String, dynamic>{};
    final classRow = _asMap(json['class']) ?? const <String, dynamic>{};

    return TeacherExamMarksGrid(
      examName: _asString(exam['name']),
      sessionName: _asString(exam['session_name']),
      datesheetName: _asString(datesheet['name']),
      className: _asString(classRow['class_name']),
      sectionName: _asString(classRow['section_name']),
      subjects: _asObjectList(json['subjects'], TeacherExamSubject.fromJson),
      students: _asObjectList(json['students'], TeacherExamStudent.fromJson),
    );
  }
}

class TeacherExamSubject {
  const TeacherExamSubject({
    required this.id,
    required this.subjectId,
    this.subjectName,
    this.examDate,
    this.totalMarks,
  });

  final int id;
  final int subjectId;
  final String? subjectName;
  final String? examDate;
  final int? totalMarks;

  String get title =>
      (subjectName ?? '').trim().isNotEmpty ? subjectName!.trim() : 'Subject';

  factory TeacherExamSubject.fromJson(Map<String, dynamic> json) {
    return TeacherExamSubject(
      id: _asInt(json['id']) ?? 0,
      subjectId: _asInt(json['subject_id']) ?? 0,
      subjectName: _asString(json['subject_name']),
      examDate: _asString(json['exam_date']),
      totalMarks: _asInt(json['total_marks']),
    );
  }
}

class TeacherExamStudent {
  const TeacherExamStudent({
    required this.id,
    this.fullName,
    this.rollNumber,
    this.marks = const [],
  });

  final int id;
  final String? fullName;
  final String? rollNumber;
  final List<TeacherExamStudentMark> marks;

  String get displayName =>
      (fullName ?? '').trim().isNotEmpty ? fullName!.trim() : 'Student';

  String get displayRoll => (rollNumber ?? '').trim();

  String get initials {
    final parts = displayName.split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    if (parts.isEmpty) return 'S';
    final first = parts.first;
    final last = parts.length > 1 ? parts.last : '';
    return ((first.isNotEmpty ? first[0] : '') + (last.isNotEmpty ? last[0] : ''))
        .toUpperCase();
  }

  factory TeacherExamStudent.fromJson(Map<String, dynamic> json) {
    return TeacherExamStudent(
      id: _asInt(json['id']) ?? 0,
      fullName: _asString(json['full_name']),
      rollNumber: _asString(json['roll_number']),
      marks: _asObjectList(json['marks'], TeacherExamStudentMark.fromJson),
    );
  }
}

class TeacherExamStudentMark {
  const TeacherExamStudentMark({
    required this.itemId,
    this.marksObtained,
    this.isAbsent = false,
  });

  final int itemId;
  final double? marksObtained;
  final bool isAbsent;

  factory TeacherExamStudentMark.fromJson(Map<String, dynamic> json) {
    return TeacherExamStudentMark(
      itemId: _asInt(json['item_id']) ?? 0,
      marksObtained: _asDouble(json['marks_obtained']),
      isAbsent: json['is_absent'] == true || json['is_absent'] == 1 || json['is_absent'] == '1',
    );
  }
}

class TeacherExamSaveResult {
  const TeacherExamSaveResult({this.saved = 0, this.message});

  final int saved;
  final String? message;
}

String displayExamDate(String? iso) {
  if (iso == null || iso.trim().isEmpty) return '';
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return iso;
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
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
