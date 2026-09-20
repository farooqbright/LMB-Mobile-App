import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/auth_session.dart';
import '../../models/teacher_attendance.dart';
import '../controllers/parent_daily_diary_controller.dart';
import '../models/parent_daily_diary.dart';
import '../services/parent_daily_diary_service.dart';

class ParentDailyDiaryView extends StatefulWidget {
  const ParentDailyDiaryView({
    super.key,
    required this.session,
    this.service,
    this.clock,
  });

  final AuthSession session;
  final ParentDailyDiaryService? service;
  final DateTime Function()? clock;

  @override
  State<ParentDailyDiaryView> createState() => _ParentDailyDiaryViewState();
}

class _ParentDailyDiaryViewState extends State<ParentDailyDiaryView> {
  late final ParentDailyDiaryController _controller = ParentDailyDiaryController(
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

  Future<void> _pickDate() async {
    final today = DateTime(
      _controller.now.year,
      _controller.now.month,
      _controller.now.day,
    );
    final picked = await showDatePicker(
      context: context,
      initialDate: _controller.selectedDate.isAfter(today)
          ? today
          : _controller.selectedDate,
      firstDate: DateTime(_controller.now.year - 2),
      lastDate: today,
    );
    if (picked == null) return;
    await _controller.selectDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.dailyDiary),
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

          final data = _controller.data ?? const ParentDailyDiaryData();
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
                      ? AppStrings.dailyDiary
                      : studentName,
                  classLabel: classLabel,
                  branchName: branchName,
                ),
                const SizedBox(height: 12),
                _FilterCard(
                  period: _controller.period,
                  selectedDate: _controller.selectedDate,
                  onPeriodSelected: _controller.selectPeriod,
                  onPickDate: _pickDate,
                  onSearch: () => _controller.selectDate(_controller.selectedDate),
                ),
                const SizedBox(height: 10),
                Text(
                  _controller.summaryLine,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                if (!data.hasEnrollment)
                  const _MessageCard(text: AppStrings.noClassEnrollment)
                else if (data.days.isEmpty)
                  _MessageCard(
                    text: '${AppStrings.noDiaryEntries} for ${_controller.rangeLabel}.',
                  )
                else
                  for (var i = 0; i < data.days.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    _DayBlock(day: data.days[i]),
                  ],
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

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.period,
    required this.selectedDate,
    required this.onPeriodSelected,
    required this.onPickDate,
    required this.onSearch,
  });

  final ParentDiaryPeriod period;
  final DateTime selectedDate;
  final ValueChanged<ParentDiaryPeriod> onPeriodSelected;
  final VoidCallback onPickDate;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final isDate = period == ParentDiaryPeriod.date;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PeriodChip(
                label: AppStrings.attendanceToday,
                selected: period == ParentDiaryPeriod.today,
                onTap: () => onPeriodSelected(ParentDiaryPeriod.today),
              ),
              _PeriodChip(
                label: AppStrings.lastWeek,
                selected: period == ParentDiaryPeriod.lastWeek,
                onTap: () => onPeriodSelected(ParentDiaryPeriod.lastWeek),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _DateField(
                  label: AppStrings.searchByDate,
                  value: displayAttendanceDate(selectedDate),
                  highlighted: isDate,
                  onTap: onPickDate,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 36,
                child: FilledButton(
                  onPressed: onSearch,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: const Text(AppStrings.search),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.navy : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? AppColors.navy : AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.text,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        Material(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: highlighted ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.muted),
                ],
              ),
            ),
          ),
        ),
      ],
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

class _DayBlock extends StatelessWidget {
  const _DayBlock({required this.day});

  final ParentDiaryDay day;

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              Text(
                day.displayDate,
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              if ((day.weekday ?? '').trim().isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  day.weekday!.trim(),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < day.entries.length; i++) ...[
            if (i > 0) const Divider(height: 20),
            _EntryCard(entry: day.entries[i]),
          ],
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});

  final ParentDiaryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.displaySubject,
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        _LabeledText(label: AppStrings.workDoneLabel, value: entry.displayWorkDone),
        const SizedBox(height: 6),
        _LabeledText(label: AppStrings.homework, value: entry.displayHomework),
      ],
    );
  }
}

class _LabeledText extends StatelessWidget {
  const _LabeledText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
