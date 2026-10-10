import 'package:flutter/material.dart';

import '../../controllers/teacher_curriculum_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/auth_session.dart';
import '../../models/teacher_curriculum.dart';
import '../../services/teacher_curriculum_service.dart';
import '../widgets/pull_to_refresh.dart';
import 'teacher_my_weeks_detail_view.dart';

class TeacherMyWeeksView extends StatefulWidget {
  const TeacherMyWeeksView({
    super.key,
    required this.session,
    this.service,
  });

  final AuthSession session;
  final TeacherCurriculumService? service;

  @override
  State<TeacherMyWeeksView> createState() => _TeacherMyWeeksViewState();
}

class _TeacherMyWeeksViewState extends State<TeacherMyWeeksView> {
  late final TeacherCurriculumController _controller = TeacherCurriculumController(
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

  void _openSubject(CurriculumSubjectSelection selection) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TeacherMyWeeksDetailView(
          session: widget.session,
          selection: selection,
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
            return _MyWeeksErrorState(
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
                children: const [
                  Icon(Icons.calendar_view_week_outlined, size: 48, color: AppColors.muted),
                  SizedBox(height: 16),
                  Text(
                    AppStrings.noMyWeeksSubjects,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    AppStrings.noMyWeeksSubjectsHint,
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
            AppStrings.myWeeksHint,
          ].whereType<String>().map((part) => part.trim()).where((part) => part.isNotEmpty).join(' — ');

          return PullToRefresh(
            color: AppColors.navy,
            onRefresh: () => _controller.load(refresh: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                const Text(
                  AppStrings.myCurriculumSubjects,
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
                const SizedBox(height: 14),
                for (var i = 0; i < data.classes.length; i++) ...[
                  _ClassCard(
                    classItem: data.classes[i],
                    onOpenSubject: (section, subject) => _openSubject(
                      CurriculumSubjectSelection(
                        classItem: data.classes[i],
                        section: section,
                        subject: subject,
                      ),
                    ),
                  ),
                  if (i != data.classes.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.classItem,
    required this.onOpenSubject,
  });

  final CurriculumClass classItem;
  final void Function(CurriculumSection section, CurriculumSubject subject)
      onOpenSubject;

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
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.displayName,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final subject in section.subjects) ...[
                    _SubjectCard(
                      classItem: classItem,
                      section: section,
                      subject: subject,
                      onTap: () => onOpenSubject(section, subject),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
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
    required this.classItem,
    required this.section,
    required this.subject,
    required this.onTap,
  });

  final CurriculumClass classItem;
  final CurriculumSection section;
  final CurriculumSubject subject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = !subject.hasPublishedPlan;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey<String>(
          'my-weeks-subject-${classItem.classId}-${section.classSectionId}-${subject.subjectId}',
        ),
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: muted ? AppColors.background : AppColors.highlightSoft,
            borderRadius: BorderRadius.circular(12),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (subject.sessionLabel.isNotEmpty) subject.sessionLabel,
                        subject.hasPublishedPlan
                            ? AppStrings.planPublished
                            : AppStrings.noPublishedPlan,
                      ].join(' · '),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12.5,
                      ),
                    ),
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

class _MyWeeksErrorState extends StatelessWidget {
  const _MyWeeksErrorState({
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
