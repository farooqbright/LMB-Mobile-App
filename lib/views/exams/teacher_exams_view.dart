import 'package:flutter/material.dart';

import '../../controllers/teacher_exam_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/auth_session.dart';
import '../../models/teacher_exam.dart';
import '../../services/teacher_exam_service.dart';
import '../widgets/pull_to_refresh.dart';
import 'teacher_exam_detail_view.dart';

class TeacherExamsView extends StatefulWidget {
  const TeacherExamsView({
    super.key,
    required this.session,
    this.service,
  });

  final AuthSession session;
  final TeacherExamService? service;

  @override
  State<TeacherExamsView> createState() => _TeacherExamsViewState();
}

class _TeacherExamsViewState extends State<TeacherExamsView> {
  late final TeacherExamController _controller = TeacherExamController(
    session: widget.session,
    service: widget.service,
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

  Future<void> _openExam(TeacherExamSummary exam) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TeacherExamDetailView(
          session: widget.session,
          examId: exam.id,
          examTitle: exam.title,
          service: widget.service,
        ),
      ),
    );
    if (!mounted) return;
    await _controller.load(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.exams),
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
            return _ExamErrorState(
              message: _controller.errorMessage!,
              onRetry: _controller.load,
            );
          }

          final data = _controller.data;
          if (data == null || data.isEmpty) {
            return PullToRefresh(
              color: AppColors.navy,
              onRefresh: () => _controller.load(refresh: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
                children: [
                  if ((data?.sessions.length ?? 0) > 1)
                    _SessionPicker(
                      sessions: data!.sessions,
                      selectedId: _controller.selectedSessionId,
                      onSelect: _controller.selectSession,
                    ),
                  if ((data?.sessions.length ?? 0) > 1) const SizedBox(height: 24),
                  const Icon(Icons.quiz_outlined, size: 48, color: AppColors.muted),
                  const SizedBox(height: 16),
                  const Text(
                    AppStrings.noExams,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    AppStrings.noExamsHint,
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

          final hint = [
            data.teacherName,
            AppStrings.examsHint,
          ].whereType<String>().map((part) => part.trim()).where((part) => part.isNotEmpty).join(' — ');

          return PullToRefresh(
            color: AppColors.navy,
            onRefresh: () => _controller.load(refresh: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                const Text(
                  AppStrings.enterExamMarks,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hint,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13.5,
                    height: 1.35,
                  ),
                ),
                if (data.sessions.length > 1) ...[
                  const SizedBox(height: 14),
                  _SessionPicker(
                    sessions: data.sessions,
                    selectedId: _controller.selectedSessionId,
                    onSelect: _controller.selectSession,
                  ),
                ] else if ((data.session?.title ?? '').isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    data.session!.title,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                for (var i = 0; i < data.exams.length; i++) ...[
                  _ExamCard(
                    exam: data.exams[i],
                    onTap: () => _openExam(data.exams[i]),
                  ),
                  if (i != data.exams.length - 1) const SizedBox(height: 12),
                ],
                if (_controller.hasMore || _controller.loadingMore) ...[
                  const SizedBox(height: 16),
                  _ExamLoadMore(
                    loading: _controller.loadingMore,
                    onPressed: _controller.loadMore,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SessionPicker extends StatelessWidget {
  const _SessionPicker({
    required this.sessions,
    required this.selectedId,
    required this.onSelect,
  });

  final List<TeacherExamSession> sessions;
  final int? selectedId;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final session in sessions)
          ChoiceChip(
            key: ValueKey<String>('exam-session-${session.id}'),
            label: Text(session.title),
            selected: selectedId == session.id,
            onSelected: (_) => onSelect(session.id),
            selectedColor: AppColors.highlightSoft,
            labelStyle: TextStyle(
              color: selectedId == session.id ? AppColors.navy : AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
            side: BorderSide(
              color: selectedId == session.id ? AppColors.navy : AppColors.border,
            ),
            backgroundColor: AppColors.surface,
          ),
      ],
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({
    required this.exam,
    required this.onTap,
  });

  final TeacherExamSummary exam;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = [
      if ((exam.sessionName ?? '').trim().isNotEmpty) exam.sessionName!.trim(),
      if (exam.dateRange.isNotEmpty) exam.dateRange,
    ].join(' · ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey<String>('exam-${exam.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
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
                child: const Icon(Icons.quiz_rounded, color: AppColors.navy),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.title,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        meta,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.enterMarks,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(label: exam.statusText, status: exam.status),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, this.status});

  final String label;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final color = switch ((status ?? '').toLowerCase()) {
      'published' => const Color(0xFF047857),
      'completed' => AppColors.navy,
      _ => AppColors.muted,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ExamErrorState extends StatelessWidget {
  const _ExamErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 42, color: AppColors.muted),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onRetry,
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
}

class _ExamLoadMore extends StatelessWidget {
  const _ExamLoadMore({
    required this.loading,
    required this.onPressed,
  });

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(color: AppColors.navy, strokeWidth: 2.4),
          ),
        ),
      );
    }

    return Center(
      child: TextButton(
        onPressed: onPressed,
        child: const Text(AppStrings.loadMore),
      ),
    );
  }
}
