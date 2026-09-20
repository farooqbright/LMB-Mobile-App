class TeacherTimetableData {
  const TeacherTimetableData({
    required this.teacher,
    required this.branches,
  });

  final TimetableTeacher teacher;
  final List<TeacherTimetableBranch> branches;

  bool get isEmpty => branches.every((branch) => branch.schedules.isEmpty);

  PeriodFocus? focusForNow(DateTime now) {
    PeriodFocus? current;
    PeriodFocus? upcoming;
    var upcomingStart = 24 * 60;

    for (final schedule in schedules) {
      final focus = PeriodFocus.resolve(
        cells: schedule.cellsForDay(now.weekday),
        now: now,
        selectedDay: now.weekday,
      );
      if (focus == null) continue;
      if (focus.kind == PeriodFocusKind.now) {
        current = focus;
        break;
      }
      final start = focus.cell.startMinutes ?? 24 * 60;
      if (start < upcomingStart) {
        upcoming = focus;
        upcomingStart = start;
      }
    }

    return current ?? upcoming;
  }

  List<TeacherSchedule> get schedules => [
        for (final branch in branches) ...branch.schedules,
      ];

  TeacherTimetableData forBranch(int branchId) {
    return TeacherTimetableData(
      teacher: teacher,
      branches: [
        for (final branch in branches)
          if (branch.branchId == branchId) branch,
      ],
    );
  }

  factory TeacherTimetableData.fromJson(
    Map<String, dynamic> json, {
    int? branchId,
  }) {
    final teacher = TimetableTeacher.fromJson(_asMap(json['teacher']) ?? const {});
    final grouped = _asObjectList(json['branches'], TeacherTimetableBranch.fromJson);
    if (grouped.isNotEmpty) {
      return TeacherTimetableData(teacher: teacher, branches: grouped);
    }

    final schedules = _asObjectList(json['schedules'], TeacherSchedule.fromJson);
    final branchJson = _asMap(json['branch']);
    if (branchJson == null && schedules.isEmpty) {
      return TeacherTimetableData(teacher: teacher, branches: const []);
    }

    return TeacherTimetableData(
      teacher: teacher,
      branches: [
        TeacherTimetableBranch(
          branchId: _asInt(branchJson?['branch_id']) ??
              (schedules.isNotEmpty ? schedules.first.branchId : null) ??
              branchId ??
              0,
          branchName: _asString(branchJson?['branch_name']) ??
              (schedules.isNotEmpty ? schedules.first.branchName : null),
          schedules: schedules,
        ),
      ],
    );
  }
}

class TimetableTeacher {
  const TimetableTeacher({
    this.userId,
    this.fullName,
    this.email,
    this.avatarUrl,
  });

  final int? userId;
  final String? fullName;
  final String? email;
  final String? avatarUrl;

  factory TimetableTeacher.fromJson(Map<String, dynamic> json) {
    return TimetableTeacher(
      userId: _asInt(json['user_id']),
      fullName: _asString(json['full_name']),
      email: _asString(json['email']),
      avatarUrl: _asString(json['avatar_url']),
    );
  }
}

class TeacherTimetableBranch {
  const TeacherTimetableBranch({
    required this.branchId,
    this.branchName,
    this.schedules = const [],
  });

  final int branchId;
  final String? branchName;
  final List<TeacherSchedule> schedules;

  String get title => (branchName ?? '').trim().isNotEmpty
      ? branchName!.trim()
      : 'Branch $branchId';

  factory TeacherTimetableBranch.fromJson(Map<String, dynamic> json) {
    return TeacherTimetableBranch(
      branchId: _asInt(json['branch_id']) ?? 0,
      branchName: _asString(json['branch_name']),
      schedules: _asObjectList(json['schedules'], TeacherSchedule.fromJson),
    );
  }
}

class TeacherSchedule {
  const TeacherSchedule({
    this.timetableId,
    this.name,
    this.label,
    this.branchId,
    this.branchName,
    this.session,
    this.slotCount = 0,
    this.workingDays = const [],
    this.periods = const [],
    this.slots = const [],
    this.grid = const [],
  });

  final int? timetableId;
  final String? name;
  final String? label;
  final int? branchId;
  final String? branchName;
  final TimetableAcademicSession? session;
  final int slotCount;
  final List<TimetableWorkingDay> workingDays;
  final List<TimetablePeriod> periods;
  final List<TimetableSlot> slots;
  final List<TimetableGridRow> grid;

  String get title {
    final heading = label?.trim();
    if (heading != null && heading.isNotEmpty) return heading;
    final value = (name ?? '').trim();
    if (value.isNotEmpty) return value;
    return 'Timetable';
  }

  String get sessionLabel {
    final value = session?.name?.trim();
    if (value == null || value.isEmpty) return '';
    return 'Session $value';
  }

  int get key => timetableId ?? identityHashCode(this);

  int defaultDay({int? weekday}) {
    final today = weekday ?? DateTime.now().weekday;
    final days = workingDays.map((day) => day.day).toSet();
    if (days.contains(today)) return today;
    if (workingDays.isNotEmpty) return workingDays.first.day;
    return today;
  }

  List<SchedulePeriodCell> cellsForDay(int day) {
    if (grid.isNotEmpty) {
      return [
        for (final row in grid)
          SchedulePeriodCell(
            periodId: row.periodId,
            periodName: row.periodName,
            startTime: row.startTime,
            endTime: row.endTime,
            lessons: row.days
                .where((cell) => cell.day == day)
                .expand((cell) => cell.lessons)
                .toList(),
          ),
      ];
    }

    return [
      for (final period in periods)
        SchedulePeriodCell(
          periodId: period.id,
          periodName: period.name,
          startTime: period.startTime,
          endTime: period.endTime,
          lessons: slots
              .where((slot) => slot.day == day && slot.periodId == period.id)
              .map((slot) => slot.toLesson())
              .toList(),
        ),
    ];
  }

  factory TeacherSchedule.fromJson(Map<String, dynamic> json) {
    return TeacherSchedule(
      timetableId: _asInt(json['timetable_id']),
      name: _asString(json['name']),
      label: _asString(json['label']),
      branchId: _asInt(json['branch_id']),
      branchName: _asString(json['branch_name']),
      session: _asMap(json['session']) == null
          ? null
          : TimetableAcademicSession.fromJson(_asMap(json['session'])!),
      slotCount: _asInt(json['slot_count']) ?? 0,
      workingDays: _asObjectList(json['working_days'], TimetableWorkingDay.fromJson),
      periods: _asObjectList(json['periods'], TimetablePeriod.fromJson),
      slots: _asObjectList(json['slots'], TimetableSlot.fromJson),
      grid: _asObjectList(json['grid'], TimetableGridRow.fromJson),
    );
  }
}

class TimetableAcademicSession {
  const TimetableAcademicSession({
    this.id,
    this.name,
    this.status,
    this.isActive = false,
  });

  final int? id;
  final String? name;
  final String? status;
  final bool isActive;

  factory TimetableAcademicSession.fromJson(Map<String, dynamic> json) {
    return TimetableAcademicSession(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      status: _asString(json['status']),
      isActive: json['is_active'] == true,
    );
  }
}

class TimetableWorkingDay {
  const TimetableWorkingDay({required this.day, this.label});

  final int day;
  final String? label;

  String get title => (label ?? '').trim().isNotEmpty ? label!.trim() : 'Day $day';

  String get shortTitle {
    if (title.length <= 3) return title;
    return title.substring(0, 3);
  }

  factory TimetableWorkingDay.fromJson(Map<String, dynamic> json) {
    return TimetableWorkingDay(
      day: _asInt(json['day']) ?? 0,
      label: _asString(json['label']),
    );
  }
}

class TimetablePeriod {
  const TimetablePeriod({
    this.id,
    this.name,
    this.startTime,
    this.endTime,
    this.sortOrder,
  });

  final int? id;
  final String? name;
  final String? startTime;
  final String? endTime;
  final int? sortOrder;

  factory TimetablePeriod.fromJson(Map<String, dynamic> json) {
    return TimetablePeriod(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      startTime: _asString(json['start_time']),
      endTime: _asString(json['end_time']),
      sortOrder: _asInt(json['sort_order']),
    );
  }
}

class TimetableSlot {
  const TimetableSlot({
    this.id,
    this.day,
    this.dayLabel,
    this.periodId,
    this.periodName,
    this.startTime,
    this.endTime,
    this.classId,
    this.className,
    this.sectionId,
    this.sectionName,
    this.subjectId,
    this.subjectName,
    this.teacherName,
    this.branchId,
    this.branchName,
  });

  final int? id;
  final int? day;
  final String? dayLabel;
  final int? periodId;
  final String? periodName;
  final String? startTime;
  final String? endTime;
  final int? classId;
  final String? className;
  final int? sectionId;
  final String? sectionName;
  final int? subjectId;
  final String? subjectName;
  final String? teacherName;
  final int? branchId;
  final String? branchName;

  TimetableLesson toLesson() {
    return TimetableLesson(
      className: className,
      sectionName: sectionName,
      subjectName: subjectName,
      teacherName: teacherName,
    );
  }

  factory TimetableSlot.fromJson(Map<String, dynamic> json) {
    return TimetableSlot(
      id: _asInt(json['id']),
      day: _asInt(json['day']),
      dayLabel: _asString(json['day_label']),
      periodId: _asInt(json['period_id']),
      periodName: _asString(json['period_name']),
      startTime: _asString(json['start_time']),
      endTime: _asString(json['end_time']),
      classId: _asInt(json['class_id']),
      className: _asString(json['class_name']),
      sectionId: _asInt(json['section_id']),
      sectionName: _asString(json['section_name']),
      subjectId: _asInt(json['subject_id']),
      subjectName: _asString(json['subject_name']),
      teacherName: _asString(json['teacher_name']),
      branchId: _asInt(json['branch_id']),
      branchName: _asString(json['branch_name']),
    );
  }
}

class TimetableGridRow {
  const TimetableGridRow({
    this.periodId,
    this.periodName,
    this.startTime,
    this.endTime,
    this.days = const [],
  });

  final int? periodId;
  final String? periodName;
  final String? startTime;
  final String? endTime;
  final List<TimetableGridDay> days;

  factory TimetableGridRow.fromJson(Map<String, dynamic> json) {
    return TimetableGridRow(
      periodId: _asInt(json['period_id']),
      periodName: _asString(json['period_name']),
      startTime: _asString(json['start_time']),
      endTime: _asString(json['end_time']),
      days: _asObjectList(json['days'], TimetableGridDay.fromJson),
    );
  }
}

class TimetableGridDay {
  const TimetableGridDay({
    required this.day,
    this.label,
    this.lessons = const [],
  });

  final int day;
  final String? label;
  final List<TimetableLesson> lessons;

  factory TimetableGridDay.fromJson(Map<String, dynamic> json) {
    return TimetableGridDay(
      day: _asInt(json['day']) ?? 0,
      label: _asString(json['label']),
      lessons: _asObjectList(json['lessons'], TimetableLesson.fromJson),
    );
  }
}

class TimetableLesson {
  const TimetableLesson({
    this.className,
    this.sectionName,
    this.subjectName,
    this.teacherName,
  });

  final String? className;
  final String? sectionName;
  final String? subjectName;
  final String? teacherName;

  String get title {
    final value = subjectName?.trim();
    if (value != null && value.isNotEmpty) return value;
    return 'Lesson';
  }

  String get subtitle {
    final teacher = teacherName?.trim();
    if (teacher != null && teacher.isNotEmpty) return teacher;
    return [
      className,
      sectionName,
    ].whereType<String>().map((part) => part.trim()).where((part) => part.isNotEmpty).join(' · ');
  }

  factory TimetableLesson.fromJson(Map<String, dynamic> json) {
    return TimetableLesson(
      className: _asString(json['class_name']),
      sectionName: _asString(json['section_name']),
      subjectName: _asString(json['subject_name']),
      teacherName: _asString(json['teacher_name']),
    );
  }
}

class SchedulePeriodCell {
  const SchedulePeriodCell({
    this.periodId,
    this.periodName,
    this.startTime,
    this.endTime,
    this.lessons = const [],
  });

  final int? periodId;
  final String? periodName;
  final String? startTime;
  final String? endTime;
  final List<TimetableLesson> lessons;

  bool get isFree => lessons.isEmpty;

  String get title {
    final value = periodName?.trim();
    if (value != null && value.isNotEmpty) return value;
    return 'Period';
  }

  String get timeRange {
    final start = startTime?.trim() ?? '';
    final end = endTime?.trim() ?? '';
    if (start.isEmpty && end.isEmpty) return '';
    if (start.isEmpty) return end;
    if (end.isEmpty) return start;
    return '$start – $end';
  }

  int? get startMinutes => parseTimetableMinutes(startTime);

  int? get endMinutes => parseTimetableMinutes(endTime);
}

enum PeriodFocusKind { now, upcoming }

class PeriodFocus {
  const PeriodFocus({
    required this.cell,
    required this.kind,
  });

  final SchedulePeriodCell cell;
  final PeriodFocusKind kind;

  bool matches(SchedulePeriodCell other) => identical(cell, other);

  /// Current slot if [now] is inside a period, otherwise the next one today.
  static PeriodFocus? resolve({
    required List<SchedulePeriodCell> cells,
    required DateTime now,
    required int selectedDay,
  }) {
    if (selectedDay != now.weekday) return null;

    final minutes = now.hour * 60 + now.minute;
    SchedulePeriodCell? current;
    SchedulePeriodCell? upcoming;
    var upcomingStart = 24 * 60;

    for (final cell in cells) {
      final start = cell.startMinutes;
      final end = cell.endMinutes;
      if (start == null || end == null || end <= start) continue;

      if (minutes >= start && minutes < end) {
        current = cell;
        break;
      }

      if (minutes < start && start < upcomingStart) {
        upcoming = cell;
        upcomingStart = start;
      }
    }

    if (current != null) {
      return PeriodFocus(cell: current, kind: PeriodFocusKind.now);
    }
    if (upcoming != null) {
      return PeriodFocus(cell: upcoming, kind: PeriodFocusKind.upcoming);
    }
    return null;
  }
}

int? parseTimetableMinutes(String? value) {
  final text = value?.trim() ?? '';
  final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(text);
  if (match == null) return null;

  final hour = int.tryParse(match.group(1)!);
  final minute = int.tryParse(match.group(2)!);
  if (hour == null || minute == null || hour > 23 || minute > 59) {
    return null;
  }
  return hour * 60 + minute;
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
