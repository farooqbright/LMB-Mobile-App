import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/network/api_exception.dart';
import '../../models/auth_session.dart';
import '../../models/teacher_exam.dart';
import '../../services/teacher_exam_service.dart';

class TeacherExamMarksView extends StatefulWidget {
  const TeacherExamMarksView({
    super.key,
    required this.session,
    required this.examId,
    required this.datesheetId,
    required this.classId,
    required this.classSectionId,
    this.heading,
    this.service,
  });

  final AuthSession session;
  final int examId;
  final int datesheetId;
  final int classId;
  final int classSectionId;
  final String? heading;
  final TeacherExamService? service;

  @override
  State<TeacherExamMarksView> createState() => _TeacherExamMarksViewState();
}

class _TeacherExamMarksViewState extends State<TeacherExamMarksView> {
  late final TeacherExamService _service = widget.service ?? TeacherExamService();
  bool _loading = true;
  bool _saving = false;
  String? _errorMessage;
  TeacherExamMarksGrid? _data;
  final Map<int, TextEditingController> _totals = {};
  final Map<String, TextEditingController> _marks = {};
  final Map<String, bool> _absent = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    for (final controller in _totals.values) {
      controller.dispose();
    }
    for (final controller in _marks.values) {
      controller.dispose();
    }
    _totals.clear();
    _marks.clear();
  }

  String _markKey(int studentId, int itemId) => '$studentId:$itemId';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final data = await _service.fetchMarks(
        widget.session,
        examId: widget.examId,
        datesheetId: widget.datesheetId,
        classId: widget.classId,
        classSectionId: widget.classSectionId,
      );
      if (!mounted) return;
      _bind(data);
      setState(() {
        _data = data;
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
        _errorMessage = 'Unable to load exam marks. Please try again.';
        _loading = false;
      });
    }
  }

  void _bind(TeacherExamMarksGrid data) {
    _disposeControllers();
    _absent.clear();

    for (final subject in data.subjects) {
      _totals[subject.id] = TextEditingController(
        text: subject.totalMarks == null ? '' : '${subject.totalMarks}',
      )..addListener(() {
          if (mounted) setState(() {});
        });
    }

    for (final student in data.students) {
      for (final subject in data.subjects) {
        TeacherExamStudentMark? existing;
        for (final mark in student.marks) {
          if (mark.itemId == subject.id) {
            existing = mark;
            break;
          }
        }
        final key = _markKey(student.id, subject.id);
        _absent[key] = existing?.isAbsent ?? false;
        _marks[key] = TextEditingController(
          text: existing?.marksObtained == null
              ? ''
              : _formatMarks(existing!.marksObtained!),
        );
      }
    }
  }

  String _formatMarks(double value) {
    if (value == value.roundToDouble()) return '${value.toInt()}';
    return value.toString();
  }

  Future<void> _save() async {
    final data = _data;
    if (data == null || _saving) return;

    final totals = <Map<String, dynamic>>[];
    for (final subject in data.subjects) {
      final raw = _totals[subject.id]?.text.trim() ?? '';
      final total = int.tryParse(raw);
      if (total == null || total < 1) {
        _showMessage(AppStrings.examTotalRequired);
        return;
      }
      totals.add({'item_id': subject.id, 'total_marks': total});
    }

    final entries = <Map<String, dynamic>>[];
    for (final student in data.students) {
      for (final subject in data.subjects) {
        final key = _markKey(student.id, subject.id);
        final isAbsent = _absent[key] == true;
        final raw = _marks[key]?.text.trim() ?? '';
        final marks = double.tryParse(raw);
        entries.add({
          'student_id': student.id,
          'item_id': subject.id,
          'is_absent': isAbsent,
          'marks_obtained': isAbsent ? null : marks,
        });
      }
    }

    setState(() => _saving = true);
    try {
      final result = await _service.saveMarks(
        widget.session,
        examId: widget.examId,
        datesheetId: widget.datesheetId,
        classId: widget.classId,
        classSectionId: widget.classSectionId,
        totals: totals,
        entries: entries,
      );
      if (!mounted) return;
      _showMessage(result.message ?? AppStrings.examMarksSaved);
    } on ApiException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to save exam marks. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _toggleAbsent(int studentId, int itemId, bool value) {
    final key = _markKey(studentId, itemId);
    setState(() {
      _absent[key] = value;
      if (value) {
        _marks[key]?.text = '';
      }
    });
  }

  String? _averageFor(TeacherExamStudent student) {
    final data = _data;
    if (data == null || data.subjects.isEmpty) return null;

    var obtained = 0.0;
    var total = 0.0;
    var counted = 0;

    for (final subject in data.subjects) {
      final key = _markKey(student.id, subject.id);
      if (_absent[key] == true) continue;
      final max = int.tryParse(_totals[subject.id]?.text.trim() ?? '');
      final marks = double.tryParse(_marks[key]?.text.trim() ?? '');
      if (max == null || max < 1 || marks == null) continue;
      obtained += marks;
      total += max;
      counted++;
    }

    if (counted == 0 || total <= 0) return null;
    return '${((obtained / total) * 100).toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.enterMarks),
      ),
      body: _buildBody(),
      bottomNavigationBar: _data == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.navy.withValues(alpha: 0.5),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(_saving ? 'Saving…' : AppStrings.saveMarks),
                ),
              ),
            ),
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
    if (data == null) {
      return const SizedBox.shrink();
    }

    final heading = data.heading.isNotEmpty ? data.heading : (widget.heading ?? AppStrings.enterMarks);
    final subtitle = [
      data.examName,
      data.datesheetName,
      data.sessionName,
      '${data.students.length} student${data.students.length == 1 ? '' : 's'}',
    ].whereType<String>().map((part) => part.trim()).where((part) => part.isNotEmpty).join(' · ');

    if (data.students.isEmpty) {
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
          const SizedBox(height: 24),
          const Text(
            AppStrings.noExamStudents,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 15, height: 1.4),
          ),
        ],
      );
    }

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
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                AppStrings.subjectTotals,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                AppStrings.subjectTotalsHint,
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              for (final subject in data.subjects)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          [
                            subject.title,
                            if (displayExamDate(subject.examDate).isNotEmpty)
                              displayExamDate(subject.examDate),
                          ].join(' · '),
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 88,
                        child: TextField(
                          controller: _totals[subject.id],
                          keyboardType: const TextInputType.numberWithOptions(decimal: false),
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            labelText: AppStrings.totalMarks,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < data.students.length; i++) ...[
          _StudentMarksCard(
            index: i + 1,
            student: data.students[i],
            subjects: data.subjects,
            marks: _marks,
            absent: _absent,
            markKey: _markKey,
            average: _averageFor(data.students[i]),
            enabled: !_saving,
            onAbsent: _toggleAbsent,
          ),
          if (i != data.students.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _StudentMarksCard extends StatelessWidget {
  const _StudentMarksCard({
    required this.index,
    required this.student,
    required this.subjects,
    required this.marks,
    required this.absent,
    required this.markKey,
    required this.average,
    required this.enabled,
    required this.onAbsent,
  });

  final int index;
  final TeacherExamStudent student;
  final List<TeacherExamSubject> subjects;
  final Map<String, TextEditingController> marks;
  final Map<String, bool> absent;
  final String Function(int studentId, int itemId) markKey;
  final String? average;
  final bool enabled;
  final void Function(int studentId, int itemId, bool value) onAbsent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.highlightSoft,
                child: Text(
                  student.initials,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$index. ${student.displayName}',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (student.displayRoll.isNotEmpty)
                      Text(
                        'Roll ${student.displayRoll}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12.5,
                        ),
                      ),
                  ],
                ),
              ),
              if (average != null)
                Text(
                  average!,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          for (final subject in subjects)
            _SubjectMarkRow(
              subject: subject,
              controller: marks[markKey(student.id, subject.id)],
              isAbsent: absent[markKey(student.id, subject.id)] == true,
              enabled: enabled,
              onAbsent: (value) => onAbsent(student.id, subject.id, value),
            ),
        ],
      ),
    );
  }
}

class _SubjectMarkRow extends StatelessWidget {
  const _SubjectMarkRow({
    required this.subject,
    required this.controller,
    required this.isAbsent,
    required this.enabled,
    required this.onAbsent,
  });

  final TeacherExamSubject subject;
  final TextEditingController? controller;
  final bool isAbsent;
  final bool enabled;
  final ValueChanged<bool> onAbsent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              subject.title,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13.5,
              ),
            ),
          ),
          SizedBox(
            width: 72,
            child: TextField(
              controller: controller,
              enabled: enabled && !isAbsent,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(
                isDense: true,
                hintText: '—',
              ),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 72,
            child: FilterChip(
              label: const Text(AppStrings.absentShort),
              selected: isAbsent,
              onSelected: enabled ? onAbsent : null,
              selectedColor: AppColors.errorSoft,
              showCheckmark: false,
              labelStyle: TextStyle(
                color: isAbsent ? AppColors.error : AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: BorderSide(color: isAbsent ? AppColors.error : AppColors.border),
            ),
          ),
        ],
      ),
    );
  }
}
