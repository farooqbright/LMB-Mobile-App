class TeacherCurriculumSubjects {
  const TeacherCurriculumSubjects({
    this.teacherName,
    this.classes = const [],
  });

  final String? teacherName;
  final List<CurriculumClass> classes;

  bool get isEmpty => classes.isEmpty;

  factory TeacherCurriculumSubjects.fromJson(Map<String, dynamic> json) {
    return TeacherCurriculumSubjects(
      teacherName: _asString(_asMap(json['teacher'])?['full_name']),
      classes: _asObjectList(json['classes'], CurriculumClass.fromJson),
    );
  }
}

class CurriculumClass {
  const CurriculumClass({
    required this.classId,
    this.className,
    this.sections = const [],
  });

  final int classId;
  final String? className;
  final List<CurriculumSection> sections;

  String get title =>
      (className ?? '').trim().isNotEmpty ? className!.trim() : 'Class';

  factory CurriculumClass.fromJson(Map<String, dynamic> json) {
    return CurriculumClass(
      classId: _asInt(json['class_id']) ?? 0,
      className: _asString(json['class_name']),
      sections: _asObjectList(json['sections'], CurriculumSection.fromJson),
    );
  }
}

class CurriculumSection {
  const CurriculumSection({
    required this.classSectionId,
    this.sectionName,
    this.subjects = const [],
  });

  final int classSectionId;
  final String? sectionName;
  final List<CurriculumSubject> subjects;

  String get title =>
      (sectionName ?? '').trim().isNotEmpty ? sectionName!.trim() : 'Section';

  String get displayName {
    final name = title;
    if (name.toLowerCase().startsWith('section')) return name;
    return 'Section $name';
  }

  factory CurriculumSection.fromJson(Map<String, dynamic> json) {
    return CurriculumSection(
      classSectionId: _asInt(json['class_section_id']) ?? 0,
      sectionName: _asString(json['section_name']),
      subjects: _asObjectList(json['subjects'], CurriculumSubject.fromJson),
    );
  }
}

class CurriculumSubject {
  const CurriculumSubject({
    required this.academicSessionId,
    required this.subjectId,
    this.sessionName,
    this.subjectName,
    this.hasPublishedPlan = false,
    this.planId,
  });

  final int academicSessionId;
  final int subjectId;
  final String? sessionName;
  final String? subjectName;
  final bool hasPublishedPlan;
  final int? planId;

  String get title =>
      (subjectName ?? '').trim().isNotEmpty ? subjectName!.trim() : 'Subject';

  String get sessionLabel => (sessionName ?? '').trim();

  factory CurriculumSubject.fromJson(Map<String, dynamic> json) {
    return CurriculumSubject(
      academicSessionId: _asInt(json['academic_session_id']) ?? 0,
      subjectId: _asInt(json['subject_id']) ?? 0,
      sessionName: _asString(json['session_name']),
      subjectName: _asString(json['subject_name']),
      hasPublishedPlan: _asBool(json['has_published_plan']),
      planId: _asInt(json['plan_id']),
    );
  }
}

class CurriculumSubjectSelection {
  const CurriculumSubjectSelection({
    required this.classItem,
    required this.section,
    required this.subject,
  });

  final CurriculumClass classItem;
  final CurriculumSection section;
  final CurriculumSubject subject;

  String get contextLabel {
    return [
      subject.title,
      classItem.title,
      section.displayName,
    ].join(' · ');
  }
}

class TeacherCurriculumWeeks {
  const TeacherCurriculumWeeks({
    this.tab = 'open',
    this.context,
    this.summary = const CurriculumWeekSummary(),
    this.terms = const [],
  });

  final String tab;
  final CurriculumWeekContext? context;
  final CurriculumWeekSummary summary;
  final List<CurriculumTerm> terms;

  bool get isEmpty => terms.every((term) => term.weeks.isEmpty);

  factory TeacherCurriculumWeeks.fromJson(Map<String, dynamic> json) {
    return TeacherCurriculumWeeks(
      tab: _asString(json['tab']) ?? 'open',
      context: _asMap(json['context']) == null
          ? null
          : CurriculumWeekContext.fromJson(_asMap(json['context'])!),
      summary: _asMap(json['summary']) == null
          ? const CurriculumWeekSummary()
          : CurriculumWeekSummary.fromJson(_asMap(json['summary'])!),
      terms: _asObjectList(json['terms'], CurriculumTerm.fromJson),
    );
  }
}

class CurriculumWeekContext {
  const CurriculumWeekContext({
    this.classId,
    this.className,
    this.classSectionId,
    this.sectionName,
    this.subjectId,
    this.subjectName,
    this.academicSessionId,
    this.sessionName,
  });

  final int? classId;
  final String? className;
  final int? classSectionId;
  final String? sectionName;
  final int? subjectId;
  final String? subjectName;
  final int? academicSessionId;
  final String? sessionName;

  String get subjectTitle =>
      (subjectName ?? '').trim().isNotEmpty ? subjectName!.trim() : 'Subject';

  String get classTitle =>
      (className ?? '').trim().isNotEmpty ? className!.trim() : 'Class';

  String get sectionTitle {
    final name = (sectionName ?? '').trim();
    if (name.isEmpty) return '';
    if (name.toLowerCase().startsWith('section')) return name;
    return 'Section $name';
  }

  String get subtitle {
    return [
      classTitle,
      if (sectionTitle.isNotEmpty) sectionTitle,
      if ((sessionName ?? '').trim().isNotEmpty) sessionName!.trim(),
    ].join(' · ');
  }

  factory CurriculumWeekContext.fromJson(Map<String, dynamic> json) {
    return CurriculumWeekContext(
      classId: _asInt(json['class_id']),
      className: _asString(json['class_name']),
      classSectionId: _asInt(json['class_section_id']),
      sectionName: _asString(json['section_name']),
      subjectId: _asInt(json['subject_id']),
      subjectName: _asString(json['subject_name']),
      academicSessionId: _asInt(json['academic_session_id']),
      sessionName: _asString(json['session_name']),
    );
  }
}

class CurriculumWeekSummary {
  const CurriculumWeekSummary({
    this.open = 0,
    this.completed = 0,
    this.total = 0,
    this.progressPercent = 0,
  });

  final int open;
  final int completed;
  final int total;
  final int progressPercent;

  factory CurriculumWeekSummary.fromJson(Map<String, dynamic> json) {
    return CurriculumWeekSummary(
      open: _asInt(json['open']) ?? 0,
      completed: _asInt(json['completed']) ?? 0,
      total: _asInt(json['total']) ?? 0,
      progressPercent: _asInt(json['progress_percent']) ?? 0,
    );
  }
}

class CurriculumTerm {
  const CurriculumTerm({
    this.id,
    this.name,
    this.startDate,
    this.endDate,
    this.count = 0,
    this.planContent,
    this.weeks = const [],
  });

  final int? id;
  final String? name;
  final String? startDate;
  final String? endDate;
  final int count;
  final String? planContent;
  final List<CurriculumWeek> weeks;

  String get title => (name ?? '').trim().isNotEmpty ? name!.trim() : 'Term';

  String get dateRange {
    final start = displayCurriculumDate(startDate);
    final end = displayCurriculumDate(endDate);
    if (start.isEmpty && end.isEmpty) return '';
    if (end.isEmpty || end == start) return start;
    return '$start – $end';
  }

  String get planText => stripCurriculumHtml(planContent);

  factory CurriculumTerm.fromJson(Map<String, dynamic> json) {
    return CurriculumTerm(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      startDate: _asString(json['start_date']),
      endDate: _asString(json['end_date']),
      count: _asInt(json['count']) ?? 0,
      planContent: _asString(json['plan_content']),
      weeks: _asObjectList(json['weeks'], CurriculumWeek.fromJson),
    );
  }
}

class CurriculumWeek {
  const CurriculumWeek({
    required this.completionId,
    this.weekNumber,
    this.weekTitle,
    this.weekStartDate,
    this.weekEndDate,
    this.status = 'pending',
    this.statusLabel,
    this.notes,
    this.dueBy,
    this.chapters = const [],
  });

  final int completionId;
  final int? weekNumber;
  final String? weekTitle;
  final String? weekStartDate;
  final String? weekEndDate;
  final String status;
  final String? statusLabel;
  final String? notes;
  final String? dueBy;
  final List<CurriculumChapter> chapters;

  String get title {
    final name = (weekTitle ?? '').trim();
    if (name.isNotEmpty) return name;
    if (weekNumber != null && weekNumber! > 0) return 'Week $weekNumber';
    return 'Week';
  }

  String get weekIndexLabel {
    if (weekNumber != null && weekNumber! > 0) return 'W$weekNumber';
    return 'W';
  }

  String get label => (statusLabel ?? '').trim().isNotEmpty
      ? statusLabel!.trim()
      : _statusFallback(status);

  bool get isCompleted => status == 'completed';
  bool get isNotCompleted => status == 'not_completed';

  int get topicCount =>
      chapters.fold(0, (sum, chapter) => sum + chapter.topics.length);

  String get chapterPreview {
    return chapters
        .map((chapter) => chapter.title)
        .where((title) => title.isNotEmpty)
        .take(2)
        .join(' · ');
  }

  String get metaLine {
    final parts = <String>[];
    if (chapterPreview.isNotEmpty) parts.add(chapterPreview);
    if (topicCount > 0) {
      parts.add('$topicCount ${topicCount == 1 ? 'topic' : 'topics'}');
    }
    final range = _weekRange();
    if (range.isNotEmpty) parts.add(range);
    final due = displayCurriculumDate(dueBy);
    if (due.isNotEmpty) parts.add('Due $due');
    return parts.join(' · ');
  }

  String _weekRange() {
    final start = displayCurriculumDate(weekStartDate);
    final end = displayCurriculumDate(weekEndDate);
    final due = displayCurriculumDate(dueBy);
    if (start.isEmpty) return '';
    if (end.isNotEmpty && end != start && end != due) return '$start – $end';
    if (start != due) return start;
    return '';
  }

  factory CurriculumWeek.fromJson(Map<String, dynamic> json) {
    return CurriculumWeek(
      completionId: _asInt(json['completion_id']) ?? 0,
      weekNumber: _asInt(json['week_number']),
      weekTitle: _asString(json['week_title']),
      weekStartDate: _asString(json['week_start_date']),
      weekEndDate: _asString(json['week_end_date']),
      status: _asString(json['status']) ?? 'pending',
      statusLabel: _asString(json['status_label']),
      notes: _asString(json['notes']),
      dueBy: _asString(json['due_by']),
      chapters: _asObjectList(json['chapters'], CurriculumChapter.fromJson),
    );
  }
}

class CurriculumChapter {
  const CurriculumChapter({
    this.title = '',
    this.description,
    this.topics = const [],
  });

  final String title;
  final String? description;
  final List<CurriculumTopic> topics;

  String get descriptionText => stripCurriculumHtml(description);

  factory CurriculumChapter.fromJson(Map<String, dynamic> json) {
    return CurriculumChapter(
      title: _asString(json['title']) ?? 'Chapter',
      description: _asString(json['description']),
      topics: _asObjectList(json['topics'], CurriculumTopic.fromJson),
    );
  }
}

class CurriculumTopic {
  const CurriculumTopic({
    this.title = '',
    this.description,
    this.isOptional = false,
  });

  final String title;
  final String? description;
  final bool isOptional;

  String get descriptionText => stripCurriculumHtml(description);

  factory CurriculumTopic.fromJson(Map<String, dynamic> json) {
    return CurriculumTopic(
      title: _asString(json['title']) ?? 'Topic',
      description: _asString(json['description']),
      isOptional: _asBool(json['is_optional']),
    );
  }
}

class CurriculumWeekUpdateResult {
  const CurriculumWeekUpdateResult({
    required this.completionId,
    required this.status,
    this.statusLabel,
    this.notes,
    this.message,
  });

  final int completionId;
  final String status;
  final String? statusLabel;
  final String? notes;
  final String? message;

  factory CurriculumWeekUpdateResult.fromJson(
    Map<String, dynamic> json, {
    String? message,
  }) {
    final completion = _asMap(json['completion']) ?? json;
    return CurriculumWeekUpdateResult(
      completionId: _asInt(completion['id']) ?? 0,
      status: _asString(completion['status']) ?? '',
      statusLabel: _asString(completion['status_label']),
      notes: _asString(completion['notes']),
      message: message,
    );
  }
}

String displayCurriculumDate(String? iso) {
  final text = (iso ?? '').trim();
  if (text.isEmpty) return '';
  final parsed = DateTime.tryParse(text);
  if (parsed == null) return text;
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

String stripCurriculumHtml(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return '';
  return text
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

String _statusFallback(String status) {
  switch (status) {
    case 'completed':
      return 'Completed';
    case 'not_completed':
      return 'Not completed';
    default:
      return 'Pending';
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
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (_asMap(item) != null) map(_asMap(item)!),
  ];
}
