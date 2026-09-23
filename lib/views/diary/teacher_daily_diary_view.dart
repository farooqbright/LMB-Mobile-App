import 'package:flutter/material.dart';

import '../../controllers/teacher_daily_diary_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/auth_session.dart';
import '../../models/teacher_daily_diary.dart';
import '../../services/teacher_daily_diary_service.dart';
import '../widgets/pull_to_refresh.dart';
import 'teacher_daily_diary_subjects_view.dart';
import 'teacher_special_remarks_view.dart';

class TeacherDailyDiaryView extends StatefulWidget {
  const TeacherDailyDiaryView({
    super.key,
    required this.session,
    this.service,
    this.clock,
    this.forSpecialRemarks = false,
  });

  final AuthSession session;
  final TeacherDailyDiaryService? service;
  final DateTime Function()? clock;
  final bool forSpecialRemarks;

  @override
  State<TeacherDailyDiaryView> createState() => _TeacherDailyDiaryViewState();
}

class _TeacherDailyDiaryViewState extends State<TeacherDailyDiaryView> {
  late final TeacherDailyDiaryController _controller = TeacherDailyDiaryController(
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

  void _openSection(DiaryClass classItem, DiarySection section) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => widget.forSpecialRemarks
            ? TeacherSpecialRemarksView(
                session: widget.session,
                classItem: classItem,
                section: section,
                service: widget.service,
                clock: widget.clock,
              )
            : TeacherDailyDiarySubjectsView(
                session: widget.session,
                classItem: classItem,
                section: section,
                service: widget.service,
                clock: widget.clock,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.forSpecialRemarks ? AppStrings.specialRemarks : AppStrings.dailyDiary,
        ),
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
            return _DiaryErrorState(
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
                  Icon(Icons.menu_book_outlined, size: 48, color: AppColors.muted),
                  SizedBox(height: 16),
                  Text(
                    AppStrings.noDiaryClasses,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    AppStrings.noDiaryClassesHint,
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
            AppStrings.myClassesHint,
          ].whereType<String>().map((part) => part.trim()).where((part) => part.isNotEmpty).join(' — ');

          return PullToRefresh(
            color: AppColors.navy,
            onRefresh: () => _controller.load(refresh: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Text(
                  AppStrings.myClasses,
                  style: const TextStyle(
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
                    onOpenSection: (section) => _openSection(data.classes[i], section),
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
    required this.onOpenSection,
  });

  final DiaryClass classItem;
  final ValueChanged<DiarySection> onOpenSection;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classItem.title,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (classItem.sessionLabel.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        classItem.sessionLabel,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
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

  final DiaryClass classItem;
  final DiarySection section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey<String>(
          'diary-class-${classItem.classId}-section-${section.classSectionId}',
        ),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: AppColors.background,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _DiaryErrorState extends StatelessWidget {
  const _DiaryErrorState({
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
