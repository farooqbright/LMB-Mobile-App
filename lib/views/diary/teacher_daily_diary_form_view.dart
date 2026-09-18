import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/network/api_exception.dart';
import '../../models/auth_session.dart';
import '../../models/teacher_daily_diary.dart';
import '../../services/teacher_daily_diary_service.dart';

class TeacherDailyDiaryFormView extends StatefulWidget {
  const TeacherDailyDiaryFormView({
    super.key,
    required this.session,
    required this.classItem,
    required this.section,
    required this.subject,
    this.service,
    this.clock,
  });

  final AuthSession session;
  final DiaryClass classItem;
  final DiarySection section;
  final DiarySubject subject;
  final TeacherDailyDiaryService? service;
  final DateTime Function()? clock;

  @override
  State<TeacherDailyDiaryFormView> createState() =>
      _TeacherDailyDiaryFormViewState();
}

class _TeacherDailyDiaryFormViewState extends State<TeacherDailyDiaryFormView> {
  late final TeacherDailyDiaryService _service =
      widget.service ?? TeacherDailyDiaryService();
  late String _date;
  final _workDone = TextEditingController();
  final _homework = TextEditingController();
  final _remarks = TextEditingController();
  final _selectedSectionIds = <int>{};

  bool _loading = true;
  bool _saving = false;
  String? _errorMessage;
  TeacherDailyDiaryEntry? _entry;

  DateTime get _now => widget.clock?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _date = isoDiaryDate(_now);
    _selectedSectionIds.add(widget.section.classSectionId);
    _load();
  }

  @override
  void dispose() {
    _workDone.dispose();
    _homework.dispose();
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final entry = await _service.fetchEntry(
        widget.session,
        classItem: widget.classItem,
        section: widget.section,
        subject: widget.subject,
        date: _date,
      );
      if (!mounted) return;
      _applyEntry(entry);
      setState(() {
        _entry = entry;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load this diary. Please try again.';
        _loading = false;
      });
    }
  }

  void _applyEntry(TeacherDailyDiaryEntry entry) {
    _workDone.text = entry.workDone ?? '';
    _homework.text = entry.homework ?? '';
    _remarks.text = entry.remarks ?? '';
    _selectedSectionIds
      ..clear()
      ..add(widget.section.classSectionId);
    final writableIds = entry.sections.map((section) => section.id).toSet();
    if (!writableIds.contains(widget.section.classSectionId) &&
        entry.sections.isNotEmpty) {
      _selectedSectionIds
        ..clear()
        ..add(entry.sections.first.id);
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

  Future<void> _save() async {
    if (_saving) return;
    final sectionIds = _sectionIdsToSave();
    if (sectionIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.selectSectionRequired)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final result = await _service.save(
        widget.session,
        classItem: widget.classItem,
        section: widget.section,
        subject: widget.subject,
        date: _date,
        sectionIds: sectionIds,
        workDone: _workDone.text,
        homework: _homework.text,
        remarks: _remarks.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.navy,
          content: Text(result.message ?? 'Daily diary saved.'),
        ),
      );
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save this diary. Please try again.')),
      );
    }
  }

  List<int> _sectionIdsToSave() {
    if (_entry == null || _entry!.sections.isEmpty) {
      return [widget.section.classSectionId];
    }
    return _selectedSectionIds.where((id) => id > 0).toList();
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

  @override
  Widget build(BuildContext context) {
    final title = _entry?.heading ?? '${widget.subject.title} — ${AppStrings.dailyDiary}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
      ),
      body: _buildBody(),
      bottomNavigationBar: _entry == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton(
                  onPressed: _saving || _loading ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(_saving ? 'Saving…' : AppStrings.saveDiary),
                ),
              ),
            ),
    );
  }

  Widget _buildBody() {
    if (_loading && _entry == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.navy),
      );
    }

    if (_errorMessage != null && _entry == null) {
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

    final entry = _entry;
    final subtitle = entry?.subtitle.isNotEmpty == true
        ? entry!.subtitle
        : [
            widget.classItem.sessionLabel,
            '${widget.classItem.title} — ${widget.section.title}',
          ].where((part) => part.trim().isNotEmpty).join(' · ');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(
          entry?.heading ?? '${widget.subject.title} — ${AppStrings.dailyDiary}',
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13.5,
              height: 1.35,
            ),
          ),
        ],
        const SizedBox(height: 16),
        _DateField(
          value: displayDiaryDate(_date),
          loading: _loading,
          onTap: _saving ? null : _pickDate,
        ),
        if (entry != null && entry.sections.isNotEmpty) ...[
          const SizedBox(height: 14),
          _SectionsPicker(
            sections: entry.sections,
            selectedIds: _selectedSectionIds,
            enabled: !_saving,
            onToggle: _toggleSection,
          ),
        ],
        const SizedBox(height: 14),
        _DiaryField(
          label: AppStrings.workDone,
          hint: AppStrings.workDoneHint,
          controller: _workDone,
          minLines: 4,
          enabled: !_saving,
        ),
        const SizedBox(height: 12),
        _DiaryField(
          label: AppStrings.homework,
          hint: AppStrings.homeworkHint,
          controller: _homework,
          minLines: 4,
          enabled: !_saving,
        ),
        const SizedBox(height: 12),
        _DiaryField(
          label: AppStrings.diaryRemarks,
          hint: AppStrings.remarksHint,
          controller: _remarks,
          minLines: 2,
          enabled: !_saving,
        ),
        const SizedBox(height: 8),
      ],
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
                _SectionChoice(
                  section: sections[i],
                  selected: selectedIds.contains(sections[i].id),
                  enabled: enabled,
                  onToggle: onToggle,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionChoice extends StatelessWidget {
  const _SectionChoice({
    required this.section,
    required this.selected,
    required this.enabled,
    required this.onToggle,
  });

  final DiaryWritableSection section;
  final bool selected;
  final bool enabled;
  final void Function(int id, bool selected) onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => onToggle(section.id, !selected) : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
        child: Row(
          children: [
            IgnorePointer(
              child: Checkbox(
                value: selected,
                onChanged: enabled ? (_) {} : null,
                activeColor: AppColors.navy,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                section.displayName,
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
            fillColor: AppColors.surface,
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
