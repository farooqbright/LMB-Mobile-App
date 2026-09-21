import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/network/api_exception.dart';
import '../../models/auth_session.dart';
import '../../models/teacher_daily_diary.dart';
import '../../models/teacher_special_remarks.dart';
import '../../services/teacher_daily_diary_service.dart';

class TeacherSpecialRemarksView extends StatefulWidget {
  const TeacherSpecialRemarksView({
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
  State<TeacherSpecialRemarksView> createState() =>
      _TeacherSpecialRemarksViewState();
}

class _TeacherSpecialRemarksViewState extends State<TeacherSpecialRemarksView> {
  late final TeacherDailyDiaryService _service =
      widget.service ?? TeacherDailyDiaryService();
  late String _date;
  final Map<int, TextEditingController> _controllers = {};

  bool _loading = true;
  bool _saving = false;
  String? _errorMessage;
  TeacherSpecialRemarksData? _data;
  List<TeacherSpecialRemarkStudent> _students = const [];

  DateTime get _now => widget.clock?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _date = isoDiaryDate(_now);
    _load();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncControllers(List<TeacherSpecialRemarkStudent> students) {
    final nextIds = students.map((student) => student.id).toSet();
    for (final id in _controllers.keys.toList()) {
      if (!nextIds.contains(id)) {
        _controllers.remove(id)?.dispose();
      }
    }
    for (final student in students) {
      final existing = _controllers[student.id];
      if (existing == null) {
        _controllers[student.id] = TextEditingController(text: student.remarks ?? '');
      } else if (existing.text != (student.remarks ?? '')) {
        existing.text = student.remarks ?? '';
      }
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final data = await _service.fetchSpecialRemarks(
        widget.session,
        classItem: widget.classItem,
        section: widget.section,
        date: _date,
      );
      if (!mounted) return;
      _syncControllers(data.students);
      setState(() {
        _data = data;
        _students = data.students;
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
        _errorMessage = 'Unable to load students. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final current = DateTime.tryParse(_date) ?? _now;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(_now.year - 1),
      lastDate: DateTime(_now.year + 1, 12, 31),
    );
    if (picked == null) return;
    final next = isoDiaryDate(picked);
    if (next == _date) return;
    setState(() => _date = next);
    await _load();
  }

  Future<void> _save() async {
    if (_saving || _loading) return;
    setState(() => _saving = true);

    try {
      final result = await _service.saveSpecialRemarks(
        widget.session,
        classItem: widget.classItem,
        section: widget.section,
        date: _date,
        remarks: [
          for (final student in _students)
            {
              'student_id': student.id,
              if (student.classSectionId != null) 'class_section_id': student.classSectionId,
              'text': _controllers[student.id]?.text ?? '',
            },
        ],
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? AppStrings.saveRemarks),
        ),
      );
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save special remarks. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final heading = _data?.heading ??
        '${widget.classItem.title} — ${widget.section.title} — ${AppStrings.specialRemarks}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.specialRemarks),
      ),
      body: _buildBody(heading),
      bottomNavigationBar: _data == null || _students.isEmpty
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
                  child: Text(_saving ? 'Saving…' : AppStrings.saveRemarks),
                ),
              ),
            ),
    );
  }

  Widget _buildBody(String heading) {
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

    if (_students.isEmpty) {
      return RefreshIndicator(
        color: AppColors.navy,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
          children: const [
            Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppColors.muted),
            SizedBox(height: 16),
            Text(
              AppStrings.noSpecialRemarksStudents,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    final subtitle = _data?.subtitle.isNotEmpty == true
        ? _data!.subtitle
        : [
            widget.classItem.sessionLabel,
            '${_students.length} student${_students.length == 1 ? '' : 's'}',
          ].where((part) => part.trim().isNotEmpty).join(' · ');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(
          heading,
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
        const SizedBox(height: 14),
        for (var i = 0; i < _students.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _StudentRemarkRow(
            student: _students[i],
            controller: _controllers[_students[i].id]!,
            enabled: !_saving && !_loading,
          ),
        ],
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
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: AppColors.navy,
                        strokeWidth: 2,
                      ),
                    )
                  else
                    const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.muted),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StudentRemarkRow extends StatelessWidget {
  const _StudentRemarkRow({
    required this.student,
    required this.controller,
    required this.enabled,
  });

  final TeacherSpecialRemarkStudent student;
  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final filled = controller.text.trim().isNotEmpty;
        return Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: filled ? const Color(0xFFF0FDFA) : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: filled ? const Color(0xFF99F6E4) : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student.title,
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              if (student.subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  student.subtitle,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              TextField(
                key: ValueKey('special-remark-${student.id}'),
                controller: controller,
                enabled: enabled,
                minLines: 2,
                maxLines: 4,
                maxLength: 2000,
                decoration: const InputDecoration(
                  labelText: AppStrings.diaryRemarks,
                  hintText: AppStrings.specialRemarkHint,
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.navy, width: 1.4),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
