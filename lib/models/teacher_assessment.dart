class TeacherAssessmentClasses {
  const TeacherAssessmentClasses({
    this.teacherName,
    this.classes = const [],
  });

  final String? teacherName;
  final List<AssessmentClass> classes;

  bool get isEmpty => classes.isEmpty;

  factory TeacherAssessmentClasses.fromJson(Map<String, dynamic> json) {
    return TeacherAssessmentClasses(
      teacherName: _asString(_asMap(json['teacher'])?['full_name']),
      classes: _asObjectList(json['classes'], AssessmentClass.fromJson),
    );
  }
}

class AssessmentClass {
  const AssessmentClass({
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
  final List<AssessmentSection> sections;

  String get title => (className ?? '').trim().isNotEmpty ? className!.trim() : 'Class';

  String get sessionLabel => (sessionName ?? '').trim();

  factory AssessmentClass.fromJson(Map<String, dynamic> json) {
    return AssessmentClass(
      academicSessionId: _asInt(json['academic_session_id']) ?? 0,
      classId: _asInt(json['class_id']) ?? 0,
      sessionName: _asString(json['session_name']),
      className: _asString(json['class_name']),
      sections: _asObjectList(json['sections'], AssessmentSection.fromJson),
    );
  }
}

class AssessmentSection {
  const AssessmentSection({
    required this.classSectionId,
    this.sectionName,
  });

  final int classSectionId;
  final String? sectionName;

  String get title => (sectionName ?? '').trim().isNotEmpty ? sectionName!.trim() : 'Section';

  String get displayName {
    final name = title;
    if (name.toLowerCase().startsWith('section')) return name;
    return 'Section $name';
  }

  factory AssessmentSection.fromJson(Map<String, dynamic> json) {
    return AssessmentSection(
      classSectionId: _asInt(json['class_section_id']) ?? 0,
      sectionName: _asString(json['section_name']),
    );
  }
}

class TeacherAssessmentSectionData {
  const TeacherAssessmentSectionData({
    this.classItem,
    this.subjects = const [],
    this.assessments = const [],
  });

  final AssessmentClassMeta? classItem;
  final List<AssessmentSubject> subjects;
  final List<TeacherAssessment> assessments;

  factory TeacherAssessmentSectionData.fromJson(Map<String, dynamic> json) {
    return TeacherAssessmentSectionData(
      classItem: json['class'] is Map
          ? AssessmentClassMeta.fromJson(_asMap(json['class']) ?? const {})
          : null,
      subjects: _asObjectList(json['subjects'], AssessmentSubject.fromJson),
      assessments: _asObjectList(json['assessments'], TeacherAssessment.fromJson),
    );
  }
}

class AssessmentClassMeta {
  const AssessmentClassMeta({
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

  String get heading {
    final classTitle = (className ?? '').trim().isNotEmpty ? className!.trim() : 'Class';
    final sectionTitle = (sectionName ?? '').trim();
    if (sectionTitle.isEmpty) return classTitle;
    return '$classTitle — $sectionTitle';
  }

  String get sessionLabel => (sessionName ?? '').trim();

  factory AssessmentClassMeta.fromJson(Map<String, dynamic> json) {
    return AssessmentClassMeta(
      academicSessionId: _asInt(json['academic_session_id']) ?? 0,
      classId: _asInt(json['class_id']) ?? 0,
      classSectionId: _asInt(json['class_section_id']) ?? 0,
      sessionName: _asString(json['session_name']),
      className: _asString(json['class_name']),
      sectionName: _asString(json['section_name']),
    );
  }
}

class AssessmentSubject {
  const AssessmentSubject({
    required this.subjectId,
    this.subjectName,
  });

  final int subjectId;
  final String? subjectName;

  String get title =>
      (subjectName ?? '').trim().isNotEmpty ? subjectName!.trim() : 'Subject';

  factory AssessmentSubject.fromJson(Map<String, dynamic> json) {
    return AssessmentSubject(
      subjectId: _asInt(json['subject_id']) ?? 0,
      subjectName: _asString(json['subject_name']),
    );
  }
}

class TeacherAssessment {
  const TeacherAssessment({
    required this.id,
    this.type,
    this.typeLabel,
    this.title,
    this.description,
    this.assessmentDate,
    this.dueDate,
    this.totalMarks,
    this.remarks,
    this.marksCount = 0,
    this.academicSessionId,
    this.classId,
    this.classSectionId,
    this.subjectId,
    this.sessionName,
    this.className,
    this.sectionName,
    this.subjectName,
  });

  final int id;
  final String? type;
  final String? typeLabel;
  final String? title;
  final String? description;
  final String? assessmentDate;
  final String? dueDate;
  final int? totalMarks;
  final String? remarks;
  final int marksCount;
  final int? academicSessionId;
  final int? classId;
  final int? classSectionId;
  final int? subjectId;
  final String? sessionName;
  final String? className;
  final String? sectionName;
  final String? subjectName;

  bool get isAssignment => type == 'assignment';

  String get displayTitle => (title ?? '').trim().isNotEmpty ? title!.trim() : 'Untitled';

  String get displayType =>
      (typeLabel ?? '').trim().isNotEmpty ? typeLabel!.trim() : (isAssignment ? 'Assignment' : 'Test');

  String get displaySubject =>
      (subjectName ?? '').trim().isNotEmpty ? subjectName!.trim() : 'Subject';

  factory TeacherAssessment.fromJson(Map<String, dynamic> json) {
    return TeacherAssessment(
      id: _asInt(json['id']) ?? 0,
      type: _asString(json['type']),
      typeLabel: _asString(json['type_label']),
      title: _asString(json['title']),
      description: _asString(json['description']),
      assessmentDate: _asString(json['assessment_date']),
      dueDate: _asString(json['due_date']),
      totalMarks: _asInt(json['total_marks']),
      remarks: _asString(json['remarks']),
      marksCount: _asInt(json['marks_count']) ?? 0,
      academicSessionId: _asInt(json['academic_session_id']),
      classId: _asInt(json['class_id']),
      classSectionId: _asInt(json['class_section_id']),
      subjectId: _asInt(json['subject_id']),
      sessionName: _asString(json['session_name']),
      className: _asString(json['class_name']),
      sectionName: _asString(json['section_name']),
      subjectName: _asString(json['subject_name']),
    );
  }
}

class TeacherAssessmentMarks {
  const TeacherAssessmentMarks({
    required this.assessment,
    this.students = const [],
  });

  final TeacherAssessment assessment;
  final List<AssessmentStudent> students;

  factory TeacherAssessmentMarks.fromJson(Map<String, dynamic> json) {
    final assessment = json['assessment'];
    return TeacherAssessmentMarks(
      assessment: TeacherAssessment.fromJson(
        assessment is Map<String, dynamic>
            ? assessment
            : Map<String, dynamic>.from(assessment is Map ? assessment : const {}),
      ),
      students: _asObjectList(json['students'], AssessmentStudent.fromJson),
    );
  }
}

class AssessmentStudent {
  const AssessmentStudent({
    required this.id,
    this.fullName,
    this.rollNumber,
    this.marksObtained,
    this.isAbsent = false,
    this.remarks,
  });

  final int id;
  final String? fullName;
  final String? rollNumber;
  final double? marksObtained;
  final bool isAbsent;
  final String? remarks;

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

  factory AssessmentStudent.fromJson(Map<String, dynamic> json) {
    return AssessmentStudent(
      id: _asInt(json['id']) ?? 0,
      fullName: _asString(json['full_name']),
      rollNumber: _asString(json['roll_number']),
      marksObtained: _asDouble(json['marks_obtained']),
      isAbsent: json['is_absent'] == true || json['is_absent'] == 1 || json['is_absent'] == '1',
      remarks: _asString(json['remarks']),
    );
  }
}

class TeacherAssessmentSaveResult {
  const TeacherAssessmentSaveResult({
    this.saved = 0,
    this.message,
    this.assessment,
  });

  final int saved;
  final String? message;
  final TeacherAssessment? assessment;
}

String isoAssessmentDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String displayAssessmentDate(String? iso) {
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
