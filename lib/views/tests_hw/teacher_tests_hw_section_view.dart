import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/network/api_exception.dart';
import '../../models/auth_session.dart';
import '../../models/teacher_assessment.dart';
import '../../services/teacher_assessment_service.dart';
import '../widgets/pull_to_refresh.dart';
import 'teacher_tests_hw_form_view.dart';
import 'teacher_tests_hw_marks_view.dart';

class TeacherTestsHwSectionView extends StatefulWidget {
  const TeacherTestsHwSectionView({
    super.key,
    required this.session,
    required this.classItem,
    required this.section,
    this.service,
    this.clock,
  });

  final AuthSession session;
  final AssessmentClass classItem;
  final AssessmentSection section;
  final TeacherAssessmentService? service;
  final DateTime Function()? clock;

  @override
  State<TeacherTestsHwSectionView> createState() => _TeacherTestsHwSectionViewState();
}

class _TeacherTestsHwSectionViewState extends State<TeacherTestsHwSectionView> {
  late final TeacherAssessmentService _service =
      widget.service ?? TeacherAssessmentService();
  bool _loading = true;
  bool _loadingMore = false;
  String? _errorMessage;
  TeacherAssessmentSectionData? _data;
  int _page = 1;

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

    _page = 1;

    try {
      final data = await _service.fetchSection(
        widget.session,
        classItem: widget.classItem,
        section: widget.section,
        page: 1,
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
        _loadingMore = false;
        _errorMessage = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        if (_data == null) _errorMessage = error.message;
        _loading = false;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (_data == null) {
          _errorMessage = 'Unable to load this class. Please try again.';
        }
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !(_data?.hasMore ?? false)) return;

    setState(() => _loadingMore = true);

    try {
      final nextPage = _page + 1;
      final result = await _service.fetchSection(
        widget.session,
        classItem: widget.classItem,
        section: widget.section,
        page: nextPage,
      );
      if (!mounted) return;
      setState(() {
        _data = (_data ?? result).mergePage(result);
        _page = result.meta.currentPage;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _openForm(AssessmentSubject subject, String type, {TeacherAssessment? existing}) async {
    final saved = await Navigator.of(context).push<TeacherAssessment>(
      MaterialPageRoute(
        builder: (_) => TeacherTestsHwFormView(
          session: widget.session,
          classItem: widget.classItem,
          section: widget.section,
          subject: subject,
          type: type,
          existing: existing,
          service: _service,
          clock: widget.clock,
        ),
      ),
    );
    if (!mounted) return;
    await _load(refresh: true);
    if (saved != null && existing == null) {
      await _openMarks(saved);
    }
  }

  Future<void> _openMarks(TeacherAssessment assessment) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TeacherTestsHwMarksView(
          session: widget.session,
          assessment: assessment,
          service: _service,
        ),
      ),
    );
    if (!mounted) return;
    await _load(refresh: true);
  }

  Future<void> _confirmDelete(TeacherAssessment assessment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteRecord),
        content: Text('Delete "${assessment.displayTitle}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final result = await _service.delete(
        widget.session,
        assessmentId: assessment.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? AppStrings.recordDeleted)),
      );
      await _load(refresh: true);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  AssessmentSubject _subjectFor(TeacherAssessment assessment) {
    for (final subject in _data?.subjects ?? const <AssessmentSubject>[]) {
      if (subject.subjectId == assessment.subjectId) return subject;
    }
    return AssessmentSubject(
      subjectId: assessment.subjectId ?? 0,
      subjectName: assessment.subjectName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final heading = _data?.classItem?.heading ??
        '${widget.classItem.title} — ${widget.section.displayName}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(heading),
      ),
      body: _buildBody(heading),
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

    final subjects = _data?.subjects ?? const <AssessmentSubject>[];
    if (subjects.isEmpty) {
      return PullToRefresh(
        color: AppColors.navy,
        onRefresh: () => _load(refresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
          children: const [
            Icon(Icons.menu_book_outlined, size: 48, color: AppColors.muted),
            SizedBox(height: 16),
            Text(
              AppStrings.noTestsHwSubjects,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              AppStrings.noTestsHwSubjectsHint,
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

    final sessionLabel = _data?.classItem?.sessionLabel ?? widget.classItem.sessionLabel;
    final assessments = _data?.assessments ?? const <TeacherAssessment>[];

    return PullToRefresh(
      color: AppColors.navy,
      onRefresh: () => _load(refresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
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
            [
              sessionLabel,
              AppStrings.chooseSubjectHint,
            ].where((part) => part.trim().isNotEmpty).join(' · '),
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < subjects.length; i++) ...[
            _SubjectCard(
              subject: subjects[i],
              className: widget.classItem.title,
              sectionName: widget.section.displayName,
              onAddTest: () => _openForm(subjects[i], 'test'),
              onAddHw: () => _openForm(subjects[i], 'assignment'),
            ),
            if (i != subjects.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 22),
          const Text(
            AppStrings.savedRecords,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            AppStrings.savedRecordsHint,
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 12),
          if (assessments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text(
                AppStrings.noSavedRecords,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 14.5, height: 1.4),
              ),
            )
          else
            for (var i = 0; i < assessments.length; i++) ...[
              _RecordCard(
                assessment: assessments[i],
                onMarks: () => _openMarks(assessments[i]),
                onEdit: () => _openForm(
                  _subjectFor(assessments[i]),
                  assessments[i].type ?? 'test',
                  existing: assessments[i],
                ),
                onDelete: () => _confirmDelete(assessments[i]),
              ),
              if (i != assessments.length - 1) const SizedBox(height: 10),
            ],
          if ((_data?.hasMore ?? false) || _loadingMore) ...[
            const SizedBox(height: 12),
            if (_loadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: AppColors.navy, strokeWidth: 2.4),
                  ),
                ),
              )
            else
              Center(
                child: TextButton(
                  onPressed: _loadMore,
                  child: const Text(AppStrings.loadMore),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.subject,
    required this.className,
    required this.sectionName,
    required this.onAddTest,
    required this.onAddHw,
  });

  final AssessmentSubject subject;
  final String className;
  final String sectionName;
  final VoidCallback onAddTest;
  final VoidCallback onAddHw;

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
                child: const Icon(Icons.menu_book_rounded, color: AppColors.navy),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.title,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$className — $sectionName',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: ValueKey<String>('add-test-${subject.subjectId}'),
                  onPressed: onAddTest,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    side: const BorderSide(color: AppColors.navy),
                  ),
                  child: const Text(AppStrings.addTest),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  key: ValueKey<String>('add-hw-${subject.subjectId}'),
                  onPressed: onAddHw,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(AppStrings.addHw),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.assessment,
    required this.onMarks,
    required this.onEdit,
    required this.onDelete,
  });

  final TeacherAssessment assessment;
  final VoidCallback onMarks;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final meta = [
      assessment.displaySubject,
      if (displayAssessmentDate(assessment.assessmentDate).isNotEmpty)
        displayAssessmentDate(assessment.assessmentDate),
      if (assessment.totalMarks != null) '${assessment.totalMarks} marks',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
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
              _TypeBadge(assessment: assessment),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  assessment.displayTitle,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              meta,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton(
                onPressed: onMarks,
                child: const Text(AppStrings.enterMarks),
              ),
              TextButton(
                onPressed: onEdit,
                child: const Text(AppStrings.edit),
              ),
              TextButton(
                onPressed: onDelete,
                child: const Text(AppStrings.delete),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.assessment});

  final TeacherAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final color = assessment.isAssignment ? const Color(0xFFB45309) : AppColors.navy;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        assessment.displayType,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
