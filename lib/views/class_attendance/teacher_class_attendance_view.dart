import 'package:flutter/material.dart';

import '../../controllers/teacher_class_attendance_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/auth_session.dart';
import '../../models/teacher_class_attendance.dart';
import '../../services/teacher_class_attendance_service.dart';
import '../widgets/pull_to_refresh.dart';
import 'teacher_class_attendance_mark_view.dart';

class TeacherClassAttendanceView extends StatefulWidget {
  const TeacherClassAttendanceView({
    super.key,
    required this.session,
    this.service,
    this.clock,
  });

  final AuthSession session;
  final TeacherClassAttendanceService? service;
  final DateTime Function()? clock;

  @override
  State<TeacherClassAttendanceView> createState() => _TeacherClassAttendanceViewState();
}

class _TeacherClassAttendanceViewState extends State<TeacherClassAttendanceView> {
  late final TeacherClassAttendanceController _controller = TeacherClassAttendanceController(
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

  Future<void> _openMark(ClassAttendanceClass classItem, ClassAttendanceSection section) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TeacherClassAttendanceMarkView(
          session: widget.session,
          classItem: classItem,
          section: section,
          service: widget.service,
          clock: widget.clock,
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
        title: const Text(AppStrings.classAttendance),
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
            return _ErrorState(
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
                  Icon(Icons.how_to_reg_outlined, size: 48, color: AppColors.muted),
                  SizedBox(height: 16),
                  Text(
                    AppStrings.noClassAttendance,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    AppStrings.noClassAttendanceHint,
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
            AppStrings.classAttendanceHint,
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
                const SizedBox(height: 12),
                _TodaySummary(summary: data.summary, date: data.date),
                const SizedBox(height: 14),
                for (var i = 0; i < data.classes.length; i++) ...[
                  _ClassCard(
                    classItem: data.classes[i],
                    onOpenSection: (section) => _openMark(data.classes[i], section),
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

class _TodaySummary extends StatelessWidget {
  const _TodaySummary({required this.summary, this.date});

  final ClassAttendanceSummary summary;
  final String? date;

  @override
  Widget build(BuildContext context) {
    final items = [
      _Stat(label: 'Students', value: '${summary.total}'),
      _Stat(label: 'Present', value: '${summary.present}'),
      _Stat(label: 'Absent', value: '${summary.absent}'),
      _Stat(label: 'Late', value: '${summary.late}'),
      _Stat(label: 'Leave', value: '${summary.leave}'),
      _Stat(label: 'Pending', value: '${summary.unmarked}'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          date == null || date!.isEmpty
              ? AppStrings.attendanceToday
              : 'Today · ${displayClassAttendanceDate(date!)}',
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 62,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                width: 78,
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      item.value,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Stat {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.classItem,
    required this.onOpenSection,
  });

  final ClassAttendanceClass classItem;
  final ValueChanged<ClassAttendanceSection> onOpenSection;

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

  final ClassAttendanceClass classItem;
  final ClassAttendanceSection section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey<String>(
          'class-att-${classItem.classId}-section-${section.classSectionId}',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.displayName,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${section.total} students · ${section.unmarked > 0 ? '${section.unmarked} pending' : 'Complete'}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                section.actionLabel,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

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
