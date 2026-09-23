import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/network/api_exception.dart';
import '../../models/auth_session.dart';
import '../../models/teacher_assessment.dart';
import '../../services/teacher_assessment_service.dart';
import '../widgets/pull_to_refresh.dart';

class TeacherTestsHwMarksView extends StatefulWidget {
  const TeacherTestsHwMarksView({
    super.key,
    required this.session,
    required this.assessment,
    this.service,
  });

  final AuthSession session;
  final TeacherAssessment assessment;
  final TeacherAssessmentService? service;

  @override
  State<TeacherTestsHwMarksView> createState() => _TeacherTestsHwMarksViewState();
}

class _TeacherTestsHwMarksViewState extends State<TeacherTestsHwMarksView> {
  late final TeacherAssessmentService _service =
      widget.service ?? TeacherAssessmentService();
  bool _loading = true;
  bool _saving = false;
  String? _errorMessage;
  TeacherAssessmentMarks? _data;
  final Map<int, TextEditingController> _marks = {};
  final Map<int, bool> _absent = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in _marks.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    if (!refresh) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final data = await _service.fetchMarks(
        widget.session,
        assessmentId: widget.assessment.id,
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
        _errorMessage = 'Unable to load student marks. Please try again.';
        _loading = false;
      });
    }
  }

  void _bind(TeacherAssessmentMarks data) {
    for (final controller in _marks.values) {
      controller.dispose();
    }
    _marks.clear();
    _absent.clear();
    for (final student in data.students) {
      _absent[student.id] = student.isAbsent;
      _marks[student.id] = TextEditingController(
        text: student.marksObtained == null ? '' : _format(student.marksObtained!),
      );
    }
  }

  String _format(double value) {
    if (value == value.roundToDouble()) return '${value.toInt()}';
    return value.toString();
  }

  Future<void> _save() async {
    final data = _data;
    if (data == null || _saving) return;

    setState(() => _saving = true);
    try {
      final result = await _service.saveMarks(
        widget.session,
        assessmentId: widget.assessment.id,
        entries: [
          for (final student in data.students)
            {
              'student_id': student.id,
              'is_absent': _absent[student.id] == true,
              'marks_obtained': _absent[student.id] == true
                  ? null
                  : double.tryParse(_marks[student.id]?.text.trim() ?? ''),
            },
        ],
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? AppStrings.examMarksSaved)),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save marks. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toggleAbsent(int studentId, bool value) {
    setState(() {
      _absent[studentId] = value;
      if (value) _marks[studentId]?.text = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final assessment = _data?.assessment ?? widget.assessment;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.enterMarks),
      ),
      body: _buildBody(assessment),
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

  Widget _buildBody(TeacherAssessment assessment) {
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
                style: const TextStyle(color: AppColors.text, fontSize: 15, height: 1.4),
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

    final students = _data?.students ?? const <AssessmentStudent>[];
    final subtitle = [
      assessment.displayType,
      assessment.displaySubject,
      if (displayAssessmentDate(assessment.assessmentDate).isNotEmpty)
        displayAssessmentDate(assessment.assessmentDate),
      if (assessment.totalMarks != null) 'Total ${assessment.totalMarks}',
      '${students.length} student${students.length == 1 ? '' : 's'}',
    ].join(' · ');

    if (students.isEmpty) {
      return PullToRefresh(
        color: AppColors.navy,
        onRefresh: () => _load(refresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(
              assessment.displayTitle,
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
        ),
      );
    }

    return PullToRefresh(
      color: AppColors.navy,
      onRefresh: () => _load(refresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
        Text(
          assessment.displayTitle,
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
        const SizedBox(height: 14),
        for (var i = 0; i < students.length; i++) ...[
          _StudentCard(
            index: i + 1,
            student: students[i],
            controller: _marks[students[i].id],
            isAbsent: _absent[students[i].id] == true,
            enabled: !_saving,
            onAbsent: (value) => _toggleAbsent(students[i].id, value),
          ),
          if (i != students.length - 1) const SizedBox(height: 10),
        ],
      ],
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.index,
    required this.student,
    required this.controller,
    required this.isAbsent,
    required this.enabled,
    required this.onAbsent,
  });

  final int index;
  final AssessmentStudent student;
  final TextEditingController? controller;
  final bool isAbsent;
  final bool enabled;
  final ValueChanged<bool> onAbsent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
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
                    style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
                  ),
              ],
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
          const SizedBox(width: 6),
          FilterChip(
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
        ],
      ),
    );
  }
}
