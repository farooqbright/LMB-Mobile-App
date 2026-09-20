import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/auth_session.dart';
import '../../models/teacher_timetable.dart';
import '../controllers/parent_timetable_controller.dart';
import '../models/parent_timetable.dart';
import '../services/parent_timetable_service.dart';

class ParentTimetableView extends StatefulWidget {
  const ParentTimetableView({
    super.key,
    required this.session,
    this.service,
    this.clock,
  });

  final AuthSession session;
  final ParentTimetableService? service;
  final DateTime Function()? clock;

  @override
  State<ParentTimetableView> createState() => _ParentTimetableViewState();
}

class _ParentTimetableViewState extends State<ParentTimetableView> {
  late final ParentTimetableController _controller = ParentTimetableController(
    session: widget.session,
    service: widget.service,
    clock: widget.clock,
  );

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.timeTable),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.loading && _controller.data == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.navy),
            );
          }

          if (_controller.errorMessage != null && _controller.data == null) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
              children: [
                Text(
                  _controller.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _controller.load,
                  child: const Text(AppStrings.retry),
                ),
              ],
            );
          }

          final data = _controller.data ?? const ParentTimetableData();
          final child = widget.session.selectedStudent;
          final studentName = (data.studentName ?? child?.title)?.trim();
          final classLabel = data.classLabel.isNotEmpty
              ? data.classLabel
              : (child?.classLabel ?? '');
          final branchName = (data.branchName ?? child?.branchName)?.trim() ?? '';

          return RefreshIndicator(
            color: AppColors.navy,
            onRefresh: () => _controller.load(refresh: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _StudentHeader(
                  name: (studentName == null || studentName.isEmpty)
                      ? AppStrings.timeTable
                      : studentName,
                  classLabel: classLabel,
                  branchName: branchName,
                ),
                const SizedBox(height: 12),
                if (!data.hasEnrollment)
                  const _MessageCard(text: AppStrings.noTimetableEnrollment)
                else if (data.schedule == null)
                  const _MessageCard(text: AppStrings.noStudentTimetable)
                else
                  _ScheduleCard(
                    schedule: data.schedule!,
                    selectedDay: _controller.currentDay,
                    now: _controller.now,
                    onSelectDay: _controller.selectDay,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StudentHeader extends StatelessWidget {
  const _StudentHeader({
    required this.name,
    required this.classLabel,
    required this.branchName,
  });

  final String name;
  final String classLabel;
  final String branchName;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (classLabel.isNotEmpty) classLabel,
      if (branchName.isNotEmpty) branchName,
    ].join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.muted,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.schedule,
    required this.selectedDay,
    required this.now,
    required this.onSelectDay,
  });

  final TeacherSchedule schedule;
  final int selectedDay;
  final DateTime now;
  final ValueChanged<int> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final cells = schedule.cellsForDay(selectedDay);
    final focus = PeriodFocus.resolve(
      cells: cells,
      now: now,
      selectedDay: selectedDay,
    );
    final meta = [
      if ((schedule.name ?? '').trim().isNotEmpty) schedule.name!.trim(),
      if (schedule.sessionLabel.isNotEmpty) schedule.sessionLabel,
      if (schedule.slotCount > 0)
        '${schedule.slotCount} assigned period${schedule.slotCount == 1 ? '' : 's'}',
    ].join(' · ');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    meta,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (schedule.workingDays.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: schedule.workingDays.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final day = schedule.workingDays[index];
                  final selected = day.day == selectedDay;
                  return ChoiceChip(
                    label: Text(day.shortTitle),
                    selected: selected,
                    onSelected: (_) => onSelectDay(day.day),
                    showCheckmark: false,
                    selectedColor: AppColors.navy,
                    backgroundColor: AppColors.background,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: selected ? AppColors.navy : AppColors.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (cells.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: Text(
                AppStrings.noPeriodsForDay,
                style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  for (final cell in cells) ...[
                    _PeriodTile(
                      cell: cell,
                      focusKind: focus != null && focus.matches(cell) ? focus.kind : null,
                    ),
                    if (cell != cells.last) const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PeriodTile extends StatelessWidget {
  const _PeriodTile({
    required this.cell,
    this.focusKind,
  });

  final SchedulePeriodCell cell;
  final PeriodFocusKind? focusKind;

  bool get _highlighted => focusKind != null;

  @override
  Widget build(BuildContext context) {
    final titleColor = _highlighted ? AppColors.navy : AppColors.text;
    final timeColor = _highlighted ? AppColors.navy : AppColors.muted;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: _highlighted ? AppColors.highlightSoft : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _highlighted ? AppColors.navy : Colors.transparent,
          width: _highlighted ? 1.4 : 0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  cell.title,
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              if (focusKind != null) ...[
                _FocusBadge(kind: focusKind!),
                const SizedBox(width: 8),
              ],
              if (cell.timeRange.isNotEmpty)
                Text(
                  cell.timeRange,
                  style: TextStyle(
                    color: timeColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (cell.isFree)
            const Text(
              AppStrings.freePeriod,
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            for (var i = 0; i < cell.lessons.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _LessonLine(lesson: cell.lessons[i]),
            ],
        ],
      ),
    );
  }
}

class _FocusBadge extends StatelessWidget {
  const _FocusBadge({required this.kind});

  final PeriodFocusKind kind;

  @override
  Widget build(BuildContext context) {
    final label = kind == PeriodFocusKind.now
        ? AppStrings.periodNow
        : AppStrings.periodUpNext;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _LessonLine extends StatelessWidget {
  const _LessonLine({required this.lesson});

  final TimetableLesson lesson;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lesson.title,
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        if (lesson.subtitle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            lesson.subtitle,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }
}
