import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/network/api_exception.dart';
import '../../models/auth_session.dart';
import '../../models/teacher_daily_diary.dart';
import '../../services/teacher_daily_diary_service.dart';
import '../widgets/pull_to_refresh.dart';

class TeacherDailyDiaryClassView extends StatefulWidget {
  const TeacherDailyDiaryClassView({
    super.key,
    required this.session,
    required this.classItem,
    required this.section,
    this.service,
    this.clock,
  });

  final AuthSession session;
  final DiaryClass classItem;
  final DiarySection section;
  final TeacherDailyDiaryService? service;
  final DateTime Function()? clock;

  @override
  State<TeacherDailyDiaryClassView> createState() =>
      _TeacherDailyDiaryClassViewState();
}

class _TeacherDailyDiaryClassViewState extends State<TeacherDailyDiaryClassView> {
  late final TeacherDailyDiaryService _service =
      widget.service ?? TeacherDailyDiaryService();
  late String _date;
  final _selectedSectionIds = <int>{};

  bool _loading = true;
  String? _errorMessage;
  TeacherClassDailyDiary? _data;

  DateTime get _now => widget.clock?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _date = isoDiaryDate(_now);
    _selectedSectionIds.add(widget.section.classSectionId);
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    if (!refresh) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final data = await _service.fetchClassDiary(
        widget.session,
        classItem: widget.classItem,
        section: widget.section,
        date: _date,
      );
      if (!mounted) return;
      final writableIds = data.sections.map((section) => section.id).toSet();
      _selectedSectionIds.removeWhere(
        (id) => writableIds.isNotEmpty && !writableIds.contains(id),
      );
      if (_selectedSectionIds.isEmpty) {
        _selectedSectionIds.add(
          writableIds.contains(widget.section.classSectionId)
              ? widget.section.classSectionId
              : (data.sections.isNotEmpty
                  ? data.sections.first.id
                  : widget.section.classSectionId),
        );
      }
      setState(() {
        _data = data;
        _errorMessage = null;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _data == null ? error.message : _errorMessage;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _data == null
            ? 'Unable to load the class diary. Please try again.'
            : _errorMessage;
        _loading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final current = DateTime.tryParse(_date) ?? _now;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(_now.year - 2),
      lastDate: DateTime(_now.year + 1, 12, 31),
    );
    if (picked == null) return;
    final next = isoDiaryDate(picked);
    if (next == _date) return;
    setState(() => _date = next);
    await _load();
  }

  void _toggleSection(int id, bool selected) {
    setState(() {
      if (selected) {
        _selectedSectionIds.add(id);
      } else {
        _selectedSectionIds.remove(id);
      }
    });
  }

  Future<void> _saveSubject(ClassDiarySubject subject, {
    required String workDone,
    required String homework,
    required String remarks,
  }) async {
    final sectionIds = _selectedSectionIds.where((id) => id > 0).toList();
    if (sectionIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.selectSectionRequired)),
      );
      return;
    }

    try {
      final result = await _service.saveClassDiary(
        widget.session,
        classItem: widget.classItem,
        section: widget.section,
        date: _date,
        sectionIds: sectionIds,
        entries: {
          subject.subjectId: {
            'work_done': workDone,
            'homework': homework,
            'remarks': remarks,
          },
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.navy,
          content: Text(result.message ?? 'Daily diary saved.'),
        ),
      );
      await _load(refresh: true);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save this diary. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${widget.classItem.title} — ${AppStrings.allSubjectsDiary}'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _data == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.navy),
      );
    }

    if (_errorMessage != null && _data == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 42, color: AppColors.muted),
              const SizedBox(height: 14),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _load,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                ),
                child: const Text(AppStrings.retry),
              ),
            ],
          ),
        ),
      );
    }

    final data = _data;
    if (data == null) return const SizedBox.shrink();
    final subtitle = data.subtitle.isNotEmpty
        ? '${data.subtitle} · ${AppStrings.classTeacherDiaryHint}'
        : AppStrings.classTeacherDiaryHint;
    final remaining = (data.totalCount - data.doneCount).clamp(0, data.totalCount);

    return PullToRefresh(
      color: AppColors.navy,
      onRefresh: () => _load(refresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            '${widget.classItem.title} — ${widget.section.title}',
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          _DateField(
            value: data.dateLabel?.trim().isNotEmpty == true
                ? data.dateLabel!
                : displayDiaryDate(_date),
            loading: _loading,
            onTap: _pickDate,
          ),
          if (data.sections.isNotEmpty) ...[
            const SizedBox(height: 14),
            _SectionsPicker(
              sections: data.sections,
              selectedIds: _selectedSectionIds,
              enabled: !_loading,
              onToggle: _toggleSection,
            ),
          ],
          if (data.subjects.isEmpty) ...[
            const SizedBox(height: 32),
            const Icon(Icons.menu_book_outlined, size: 48, color: AppColors.muted),
            const SizedBox(height: 16),
            const Text(
              AppStrings.noClassDiarySubjects,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            Text(
              '${displayDiaryDate(_date)}: ${data.doneCount} ${AppStrings.diarySubjectDone.toLowerCase()} · $remaining ${AppStrings.diarySubjectRemaining.toLowerCase()}',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < data.subjects.length; i++) ...[
              _ClassSubjectCard(
                key: ValueKey<String>('class-diary-${data.subjects[i].subjectId}-$_date'),
                subject: data.subjects[i],
                onSave: (workDone, homework, remarks) => _saveSubject(
                  data.subjects[i],
                  workDone: workDone,
                  homework: homework,
                  remarks: remarks,
                ),
              ),
              if (i != data.subjects.length - 1) const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }
}

class _ClassSubjectCard extends StatefulWidget {
  const _ClassSubjectCard({
    super.key,
    required this.subject,
    required this.onSave,
  });

  final ClassDiarySubject subject;
  final Future<void> Function(String workDone, String homework, String remarks)
      onSave;

  @override
  State<_ClassSubjectCard> createState() => _ClassSubjectCardState();
}

class _ClassSubjectCardState extends State<_ClassSubjectCard> {
  late final TextEditingController _workDone =
      TextEditingController(text: widget.subject.workDone ?? '');
  late final TextEditingController _homework =
      TextEditingController(text: widget.subject.homework ?? '');
  late final TextEditingController _remarks =
      TextEditingController(text: widget.subject.remarks ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _workDone.dispose();
    _homework.dispose();
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(_workDone.text, _homework.text, _remarks.text);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subject = widget.subject;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: subject.isDone ? AppColors.success.withValues(alpha: 0.35) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  subject.title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: subject.isDone ? AppColors.successSoft : AppColors.warningSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  subject.isDone
                      ? AppStrings.diarySubjectDone
                      : AppStrings.diarySubjectRemaining,
                  style: TextStyle(
                    color: subject.isDone ? AppColors.success : AppColors.warning,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DiaryField(
            label: AppStrings.workDone,
            hint: AppStrings.workDoneHint,
            controller: _workDone,
            minLines: 3,
            enabled: !_saving,
          ),
          const SizedBox(height: 10),
          _DiaryField(
            label: AppStrings.homework,
            hint: AppStrings.homeworkHint,
            controller: _homework,
            minLines: 3,
            enabled: !_saving,
          ),
          const SizedBox(height: 10),
          _DiaryField(
            label: AppStrings.diaryRemarks,
            hint: AppStrings.remarksHint,
            controller: _remarks,
            minLines: 2,
            enabled: !_saving,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              key: ValueKey<String>('class-diary-save-${subject.subjectId}'),
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
              ),
              child: Text(
                _saving
                    ? 'Saving…'
                    : (subject.isDone ? AppStrings.update : AppStrings.save),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.value,
    required this.onTap,
    this.loading = false,
  });

  final String value;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          AppStrings.diaryDate,
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (loading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.navy,
                      ),
                    )
                  else
                    const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.muted),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionsPicker extends StatelessWidget {
  const _SectionsPicker({
    required this.sections,
    required this.selectedIds,
    required this.enabled,
    required this.onToggle,
  });

  final List<DiaryWritableSection> sections;
  final Set<int> selectedIds;
  final bool enabled;
  final void Function(int id, bool selected) onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          AppStrings.applyToSections,
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          AppStrings.applyToSectionsHint,
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 13,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < sections.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.border),
                InkWell(
                  onTap: enabled
                      ? () => onToggle(sections[i].id, !selectedIds.contains(sections[i].id))
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
                    child: Row(
                      children: [
                        IgnorePointer(
                          child: Checkbox(
                            value: selectedIds.contains(sections[i].id),
                            onChanged: enabled ? (_) {} : null,
                            activeColor: AppColors.navy,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            sections[i].displayName,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DiaryField extends StatelessWidget {
  const _DiaryField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.minLines,
    required this.enabled,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final int minLines;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          minLines: minLines,
          maxLines: minLines + 3,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.navy, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}
