import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/network/api_exception.dart';
import '../../models/auth_session.dart';
import '../../models/teacher_daily_diary.dart';
import '../../services/teacher_daily_diary_service.dart';
import 'teacher_daily_diary_form_view.dart';
import 'teacher_special_remarks_view.dart';

class TeacherDailyDiarySubjectsView extends StatefulWidget {
  const TeacherDailyDiarySubjectsView({
    super.key,
    required this.session,
    required this.classItem,
    required this.section,
    this.service,
    this.clock,
  });

  final AuthSession session;
  final DiaryClass classItem;
  final DiarySection section;
  final TeacherDailyDiaryService? service;
  final DateTime Function()? clock;

  @override
  State<TeacherDailyDiarySubjectsView> createState() =>
      _TeacherDailyDiarySubjectsViewState();
}

class _TeacherDailyDiarySubjectsViewState extends State<TeacherDailyDiarySubjectsView> {
  late final TeacherDailyDiaryService _service =
      widget.service ?? TeacherDailyDiaryService();

  bool _loading = true;
  String? _errorMessage;
  TeacherDailyDiarySubjects? _data;

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
      final data = await _service.fetchSubjects(
        widget.session,
        classItem: widget.classItem,
        section: widget.section,
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _errorMessage = null;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _data == null ? error.message : _errorMessage;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _data == null
            ? 'Unable to load your subjects. Please try again.'
            : _errorMessage;
        _loading = false;
      });
    }
  }

  void _openForm(DiarySubject subject) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TeacherDailyDiaryFormView(
          session: widget.session,
          classItem: widget.classItem,
          section: widget.section,
          subject: subject,
          service: _service,
          clock: widget.clock,
        ),
      ),
    );
  }

  void _openSpecialRemarks() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TeacherSpecialRemarksView(
          session: widget.session,
          classItem: widget.classItem,
          section: widget.section,
          service: _service,
          clock: widget.clock,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final heading = '${widget.classItem.title} — ${widget.section.title}';

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
      return _SubjectsErrorState(
        message: _errorMessage!,
        onRetry: _load,
      );
    }

    final subjects = _data?.subjects ?? const <DiarySubject>[];
    if (subjects.isEmpty) {
      return RefreshIndicator(
        color: AppColors.navy,
        onRefresh: () => _load(refresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
          children: const [
            Icon(Icons.menu_book_outlined, size: 48, color: AppColors.muted),
            SizedBox(height: 16),
            Text(
              AppStrings.noDiarySubjects,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              AppStrings.noDiarySubjectsHint,
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

    final sessionLabel = (_data?.classItem.sessionLabel.isNotEmpty ?? false)
        ? _data!.classItem.sessionLabel
        : widget.classItem.sessionLabel;
    final subtitle = [
      sessionLabel,
      'subjects from your timetable',
    ].where((part) => part.trim().isNotEmpty).join(' · ');

    return RefreshIndicator(
      color: AppColors.navy,
      onRefresh: () => _load(refresh: true),
      child: ListView(
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
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: _openSpecialRemarks,
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: const Text(AppStrings.specialRemarks),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                side: const BorderSide(color: AppColors.navy),
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < subjects.length; i++) ...[
            _SubjectCard(
              subject: subjects[i],
              className: widget.classItem.title,
              sectionName: widget.section.title,
              onAdd: () => _openForm(subjects[i]),
            ),
            if (i != subjects.length - 1) const SizedBox(height: 10),
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
    required this.onAdd,
  });

  final DiarySubject subject;
  final String className;
  final String sectionName;
  final VoidCallback onAdd;

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
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text(AppStrings.addDiary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectsErrorState extends StatelessWidget {
  const _SubjectsErrorState({
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
