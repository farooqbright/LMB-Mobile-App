import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/network/api_exception.dart';
import '../../models/auth_session.dart';
import '../../models/teacher_assessment.dart';
import '../../services/teacher_assessment_service.dart';

class TeacherTestsHwFormView extends StatefulWidget {
  const TeacherTestsHwFormView({
    super.key,
    required this.session,
    required this.classItem,
    required this.section,
    required this.subject,
    required this.type,
    this.existing,
    this.service,
    this.clock,
  });

  final AuthSession session;
  final AssessmentClass classItem;
  final AssessmentSection section;
  final AssessmentSubject subject;
  final String type;
  final TeacherAssessment? existing;
  final TeacherAssessmentService? service;
  final DateTime Function()? clock;

  @override
  State<TeacherTestsHwFormView> createState() => _TeacherTestsHwFormViewState();
}

class _TeacherTestsHwFormViewState extends State<TeacherTestsHwFormView> {
  late final TeacherAssessmentService _service =
      widget.service ?? TeacherAssessmentService();
  late String _type;
  late String _date;
  String? _dueDate;
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _totalMarks = TextEditingController();
  final _remarks = TextEditingController();
  bool _saving = false;

  DateTime get _now => widget.clock?.call() ?? DateTime.now();

  bool get _isAssignment => _type == 'assignment';

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _type = existing?.type ?? widget.type;
    _date = existing?.assessmentDate ?? isoAssessmentDate(_now);
    _dueDate = existing?.dueDate;
    _title.text = existing?.title ?? '';
    _description.text = existing?.description ?? '';
    _totalMarks.text = existing?.totalMarks == null ? '' : '${existing!.totalMarks}';
    _remarks.text = existing?.remarks ?? '';
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _totalMarks.dispose();
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool due}) async {
    final current = DateTime.tryParse(due ? (_dueDate ?? _date) : _date) ?? _now;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(_now.year - 1),
      lastDate: DateTime(_now.year + 1, 12, 31),
    );
    if (picked == null) return;
    setState(() {
      final next = isoAssessmentDate(picked);
      if (due) {
        _dueDate = next;
      } else {
        _date = next;
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final title = _title.text.trim();
    if (title.isEmpty) {
      _showMessage(AppStrings.titleRequired);
      return;
    }

    setState(() => _saving = true);
    try {
      final result = await _service.save(
        widget.session,
        classItem: widget.classItem,
        section: widget.section,
        subject: widget.subject,
        existing: widget.existing,
        type: _type,
        title: title,
        description: _description.text,
        assessmentDate: _date,
        dueDate: _isAssignment ? _dueDate : null,
        totalMarks: int.tryParse(_totalMarks.text.trim()),
        remarks: _remarks.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? AppStrings.recordSaved)),
      );
      Navigator.of(context).pop(result.assessment);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('Unable to save this record. Please try again.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final heading = widget.existing == null
        ? (_isAssignment ? AppStrings.addHw : AppStrings.addTest)
        : AppStrings.editRecord;
    final subtitle = [
      widget.subject.title,
      '${widget.classItem.title} — ${widget.section.displayName}',
      widget.classItem.sessionLabel,
    ].where((part) => part.trim().isNotEmpty).join(' · ');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(heading),
      ),
      body: ListView(
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
          _Field(
            label: AppStrings.title,
            hint: _isAssignment ? 'e.g. Chapter 3 homework' : 'e.g. Chapter 3 Test',
            controller: _title,
            enabled: !_saving,
          ),
          const SizedBox(height: 12),
          _DateRow(
            label: AppStrings.assessmentDate,
            value: displayAssessmentDate(_date),
            onTap: _saving ? null : () => _pickDate(due: false),
          ),
          if (_isAssignment) ...[
            const SizedBox(height: 12),
            _DateRow(
              label: AppStrings.dueDate,
              value: _dueDate == null ? AppStrings.optional : displayAssessmentDate(_dueDate),
              onTap: _saving ? null : () => _pickDate(due: true),
            ),
          ],
          const SizedBox(height: 12),
          _Field(
            label: AppStrings.totalMarksLabel,
            hint: AppStrings.optional,
            controller: _totalMarks,
            enabled: !_saving,
            keyboardType: TextInputType.number,
            digitsOnly: true,
          ),
          const SizedBox(height: 12),
          _Field(
            label: AppStrings.description,
            hint: AppStrings.descriptionHint,
            controller: _description,
            enabled: !_saving,
            minLines: 3,
          ),
          const SizedBox(height: 12),
          _Field(
            label: AppStrings.diaryRemarks,
            hint: AppStrings.remarksHint,
            controller: _remarks,
            enabled: !_saving,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
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
            child: Text(_saving ? 'Saving…' : (widget.existing == null ? AppStrings.save : AppStrings.update)),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    required this.enabled,
    this.minLines = 1,
    this.keyboardType,
    this.digitsOnly = false,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool enabled;
  final int minLines;
  final TextInputType? keyboardType;
  final bool digitsOnly;

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
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          minLines: minLines,
          maxLines: minLines > 1 ? minLines + 2 : 1,
          keyboardType: keyboardType,
          inputFormatters: digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

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
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
