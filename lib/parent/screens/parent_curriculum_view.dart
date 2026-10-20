import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/auth_session.dart';
import '../../views/widgets/pull_to_refresh.dart';
import '../controllers/parent_curriculum_controller.dart';
import '../models/parent_curriculum.dart';
import '../services/parent_curriculum_service.dart';
import 'parent_curriculum_detail_view.dart';

class ParentCurriculumView extends StatefulWidget {
  const ParentCurriculumView({
    super.key,
    required this.session,
    this.service,
  });

  final AuthSession session;
  final ParentCurriculumService? service;

  @override
  State<ParentCurriculumView> createState() => _ParentCurriculumViewState();
}

class _ParentCurriculumViewState extends State<ParentCurriculumView> {
  late final ParentCurriculumController _controller = ParentCurriculumController(
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

  void _openSubject(ParentCurriculumSubject subject) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ParentCurriculumDetailView(
          session: widget.session,
          subject: subject,
          service: widget.service,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.myWeeks),
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
            return PullToRefresh(
              color: AppColors.navy,
              onRefresh: () => _controller.load(refresh: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
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
              ),
            );
          }

          final data = _controller.data ?? const ParentCurriculumSubjects();
          final child = widget.session.selectedStudent;
          final studentName = (data.studentName ?? child?.title)?.trim();
          final classLabel = data.classLabel.isNotEmpty
              ? data.classLabel
              : (child?.classLabel ?? '');
          final branchName = (data.branchName ?? child?.branchName)?.trim() ?? '';

          return PullToRefresh(
            color: AppColors.navy,
            onRefresh: () => _controller.load(refresh: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _StudentHeader(
                  name: (studentName == null || studentName.isEmpty)
                      ? AppStrings.myWeeks
                      : studentName,
                  classLabel: classLabel,
                  branchName: branchName,
                  sessionName: data.sessionName ?? '',
                ),
                const SizedBox(height: 12),
                const Text(
                  AppStrings.parentCurriculumHint,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 13.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                if (!data.hasEnrollment)
                  const _MessageCard(text: AppStrings.noCurriculumEnrollment)
                else if (data.isEmpty)
                  const _MessageCard(
                    title: AppStrings.noCurriculumSubjects,
                    text: AppStrings.noCurriculumSubjectsHint,
                  )
                else
                  for (var i = 0; i < data.subjects.length; i++) ...[
                    _SubjectCard(
                      subject: data.subjects[i],
                      classLabel: classLabel,
                      onTap: () => _openSubject(data.subjects[i]),
                    ),
                    if (i != data.subjects.length - 1) const SizedBox(height: 10),
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
    required this.sessionName,
  });

  final String name;
  final String classLabel;
  final String branchName;
  final String sessionName;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (classLabel.isNotEmpty) classLabel,
      if (branchName.isNotEmpty) branchName,
      if (sessionName.trim().isNotEmpty) sessionName.trim(),
    ].join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.subject,
    required this.classLabel,
    required this.onTap,
  });

  final ParentCurriculumSubject subject;
  final String classLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = !subject.hasPlan;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey<String>('parent-curriculum-subject-${subject.subjectId}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: muted ? AppColors.background : AppColors.highlightSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.title,
                      style: TextStyle(
                        color: muted ? AppColors.muted : AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (classLabel.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        classLabel,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      subject.hasPlan
                          ? AppStrings.viewCurriculum
                          : AppStrings.noCurriculumYet,
                      style: TextStyle(
                        color: subject.hasPlan ? AppColors.navy : AppColors.muted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subject.progressLine.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subject.progressLine,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: muted ? AppColors.muted : AppColors.navy,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    this.title,
    required this.text,
  });

  final String? title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          if ((title ?? '').trim().isNotEmpty) ...[
            Text(
              title!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 14.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
