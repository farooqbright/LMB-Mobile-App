import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/network/api_exception.dart';
import '../../models/auth_session.dart';
import '../../models/teacher_exam.dart';
import '../../services/teacher_exam_service.dart';
import '../widgets/pull_to_refresh.dart';
import 'teacher_exam_marks_view.dart';

class TeacherExamDetailView extends StatefulWidget {
  const TeacherExamDetailView({
    super.key,
    required this.session,
    required this.examId,
    this.examTitle,
    this.service,
  });

  final AuthSession session;
  final int examId;
  final String? examTitle;
  final TeacherExamService? service;

  @override
  State<TeacherExamDetailView> createState() => _TeacherExamDetailViewState();
}

class _TeacherExamDetailViewState extends State<TeacherExamDetailView> {
  late final TeacherExamService _service = widget.service ?? TeacherExamService();
  bool _loading = true;
  String? _errorMessage;
  TeacherExamSummary? _exam;

  @override
  void initState() {
    super.initState();
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
      final exam = await _service.fetchExam(widget.session, examId: widget.examId);
      if (!mounted) return;
      setState(() {
        _exam = exam;
        _loading = false;
        _errorMessage = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        if (_exam == null) _errorMessage = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (_exam == null) {
          _errorMessage = 'Unable to load exam datesheets. Please try again.';
        }
        _loading = false;
      });
    }
  }

  Future<void> _openMarks(TeacherExamDatesheet datesheet, TeacherExamClass classItem, TeacherExamSection section) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TeacherExamMarksView(
          session: widget.session,
          examId: widget.examId,
          datesheetId: datesheet.id,
          classId: classItem.classId,
          classSectionId: section.classSectionId,
          heading: '${classItem.title} — ${section.displayName}',
          service: widget.service,
        ),
      ),
    );
    if (!mounted) return;
    await _load(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final exam = _exam;
    final title = exam?.title ?? widget.examTitle ?? AppStrings.exams;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
      ),
      body: _buildBody(exam),
    );
  }

  Widget _buildBody(TeacherExamSummary? exam) {
    if (_loading && exam == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.navy),
      );
    }

    if (_errorMessage != null && exam == null) {
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

    if (exam == null || exam.datesheets.isEmpty) {
      return PullToRefresh(
        color: AppColors.navy,
        onRefresh: () => _load(refresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
          children: const [
            Icon(Icons.event_note_outlined, size: 48, color: AppColors.muted),
            SizedBox(height: 16),
            Text(
              AppStrings.noExamDatesheets,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              AppStrings.noExamDatesheetsHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 15,
                height: 1.45,
              ),
            ),
          ],
        ),
      );
    }

    final meta = [
      if ((exam.sessionName ?? '').trim().isNotEmpty) exam.sessionName!.trim(),
      if (exam.dateRange.isNotEmpty) exam.dateRange,
      exam.statusText,
    ].join(' · ');

    return PullToRefresh(
      color: AppColors.navy,
      onRefresh: () => _load(refresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            exam.title,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              meta,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13.5,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 6),
          const Text(
            AppStrings.examDatesheetsHint,
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 13.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < exam.datesheets.length; i++) ...[
            _DatesheetCard(
              datesheet: exam.datesheets[i],
              onOpenSection: (classItem, section) =>
                  _openMarks(exam.datesheets[i], classItem, section),
            ),
            if (i != exam.datesheets.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _DatesheetCard extends StatelessWidget {
  const _DatesheetCard({
    required this.datesheet,
    required this.onOpenSection,
  });

  final TeacherExamDatesheet datesheet;
  final void Function(TeacherExamClass classItem, TeacherExamSection section) onOpenSection;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.highlightSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.event_note_rounded, color: AppColors.navy),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  datesheet.title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          for (final classItem in datesheet.classes) ...[
            const SizedBox(height: 12),
            _ClassCard(
              classItem: classItem,
              onOpenSection: (section) => onOpenSection(classItem, section),
            ),
          ],
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.classItem,
    required this.onOpenSection,
  });

  final TeacherExamClass classItem;
  final ValueChanged<TeacherExamSection> onOpenSection;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.highlightSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school_rounded, color: AppColors.navy),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  classItem.title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          for (final section in classItem.sections) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: _SectionCard(
                classItem: classItem,
                section: section,
                onTap: () => onOpenSection(section),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.classItem,
    required this.section,
    required this.onTap,
  });

  final TeacherExamClass classItem;
  final TeacherExamSection section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey<String>(
          'exam-class-${classItem.classId}-section-${section.classSectionId}',
        ),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.highlightSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.groups_rounded, color: AppColors.navy),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  section.displayName,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const Text(
                AppStrings.enterMarks,
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
