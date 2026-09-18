class TeacherDailyDiaryClasses {
  const TeacherDailyDiaryClasses({
    this.teacherName,
    this.classes = const [],
  });

  final String? teacherName;
  final List<DiaryClass> classes;

  bool get isEmpty => classes.isEmpty;

  factory TeacherDailyDiaryClasses.fromJson(Map<String, dynamic> json) {
    return TeacherDailyDiaryClasses(
      teacherName: _asString(_asMap(json['teacher'])?['full_name']),
      classes: _asObjectList(json['classes'], DiaryClass.fromJson),
    );
  }
}

class DiaryClass {
  const DiaryClass({
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
  final List<DiarySection> sections;

  String get title => (className ?? '').trim().isNotEmpty ? className!.trim() : 'Class';

  String get sessionLabel => (sessionName ?? '').trim();

  String get footerLabel {
    if (sections.length == 1) {
      return sections.first.title;
    }
    return '${sections.length} sections';
  }

  factory DiaryClass.fromJson(Map<String, dynamic> json) {
    return DiaryClass(
      academicSessionId: _asInt(json['academic_session_id']) ?? 0,
      classId: _asInt(json['class_id']) ?? 0,
      sessionName: _asString(json['session_name']),
      className: _asString(json['class_name']),
      sections: _asObjectList(json['sections'], DiarySection.fromJson),
    );
  }
}

class DiarySection {
  const DiarySection({
    required this.classSectionId,
    this.sectionName,
    this.subjectCount = 0,
  });

  final int classSectionId;
  final String? sectionName;
  final int subjectCount;

  String get title => (sectionName ?? '').trim().isNotEmpty ? sectionName!.trim() : 'Section';

  String get displayName {
    final name = title;
    if (name.toLowerCase().startsWith('section')) return name;
    return 'Section $name';
  }

  factory DiarySection.fromJson(Map<String, dynamic> json) {
    return DiarySection(
      classSectionId: _asInt(json['class_section_id']) ?? 0,
      sectionName: _asString(json['section_name']),
      subjectCount: _asInt(json['subject_count']) ?? 0,
    );
  }
}

class TeacherDailyDiarySubjects {
  const TeacherDailyDiarySubjects({
    required this.classItem,
    this.sectionName,
    this.subjects = const [],
  });

  final DiaryClass classItem;
  final String? sectionName;
  final List<DiarySubject> subjects;

  factory TeacherDailyDiarySubjects.fromJson(Map<String, dynamic> json) {
    final classJson = _asMap(json['class']) ?? const {};
    return TeacherDailyDiarySubjects(
      classItem: DiaryClass(
        academicSessionId: _asInt(classJson['academic_session_id']) ?? 0,
        classId: _asInt(classJson['class_id']) ?? 0,
        sessionName: _asString(classJson['session_name']),
        className: _asString(classJson['class_name']),
        sections: [
          DiarySection(
            classSectionId: _asInt(classJson['class_section_id']) ?? 0,
            sectionName: _asString(classJson['section_name']),
          ),
        ],
      ),
      sectionName: _asString(classJson['section_name']),
      subjects: _asObjectList(json['subjects'], DiarySubject.fromJson),
    );
  }
}

class DiarySubject {
  const DiarySubject({
    required this.academicSessionId,
    required this.classId,
    required this.classSectionId,
    required this.subjectId,
    this.subjectName,
  });

  final int academicSessionId;
  final int classId;
  final int classSectionId;
  final int subjectId;
  final String? subjectName;

  String get title => (subjectName ?? '').trim().isNotEmpty ? subjectName!.trim() : 'Subject';

  factory DiarySubject.fromJson(Map<String, dynamic> json) {
    return DiarySubject(
      academicSessionId: _asInt(json['academic_session_id']) ?? 0,
      classId: _asInt(json['class_id']) ?? 0,
      classSectionId: _asInt(json['class_section_id']) ?? 0,
      subjectId: _asInt(json['subject_id']) ?? 0,
      subjectName: _asString(json['subject_name']),
    );
  }
}

class TeacherDailyDiaryEntry {
  const TeacherDailyDiaryEntry({
    required this.date,
    this.workDone,
    this.homework,
    this.remarks,
    this.subjectName,
    this.className,
    this.sectionName,
    this.sessionName,
    this.sections = const [],
  });

  final String date;
  final String? workDone;
  final String? homework;
  final String? remarks;
  final String? subjectName;
  final String? className;
  final String? sectionName;
  final String? sessionName;
  final List<DiaryWritableSection> sections;

  String get heading {
    final subject = (subjectName ?? '').trim();
    if (subject.isEmpty) return 'Daily Diary';
    return '$subject — Daily Diary';
  }

  String get subtitle {
    return [
      sessionName,
      [className, sectionName].whereType<String>().map((part) => part.trim()).where((part) => part.isNotEmpty).join(' — '),
    ].whereType<String>().map((part) => part.trim()).where((part) => part.isNotEmpty).join(' · ');
  }

  factory TeacherDailyDiaryEntry.fromJson(Map<String, dynamic> json) {
    final target = _asMap(json['target']) ?? const {};
    final entry = _asMap(json['entry']) ?? const {};
    return TeacherDailyDiaryEntry(
      date: _asString(json['date']) ?? '',
      workDone: _asString(entry['work_done']),
      homework: _asString(entry['homework']),
      remarks: _asString(entry['remarks']),
      subjectName: _asString(target['subject_name']),
      className: _asString(target['class_name']),
      sectionName: _asString(target['section_name']),
      sessionName: _asString(target['session_name']),
      sections: _asObjectList(json['sections'], DiaryWritableSection.fromJson),
    );
  }
}

class DiaryWritableSection {
  const DiaryWritableSection({required this.id, this.name});

  final int id;
  final String? name;

  String get title => (name ?? '').trim().isNotEmpty ? name!.trim() : 'Section';

  String get displayName {
    final label = title;
    if (label.toLowerCase().startsWith('section')) return label;
    return 'Section $label';
  }

  factory DiaryWritableSection.fromJson(Map<String, dynamic> json) {
    return DiaryWritableSection(
      id: _asInt(json['id']) ?? 0,
      name: _asString(json['name']),
    );
  }
}

class TeacherDailyDiarySaveResult {
  const TeacherDailyDiarySaveResult({this.saved = 0, this.message});

  final int saved;
  final String? message;
}

String isoDiaryDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String displayDiaryDate(String iso) {
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
