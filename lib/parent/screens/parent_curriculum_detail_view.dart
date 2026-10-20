import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/network/api_exception.dart';
import '../../models/auth_session.dart';
import '../../models/teacher_curriculum.dart';
import '../../views/widgets/pull_to_refresh.dart';
import '../models/parent_curriculum.dart';
import '../services/parent_curriculum_service.dart';

class ParentCurriculumDetailView extends StatefulWidget {
  const ParentCurriculumDetailView({
    super.key,
    required this.session,
    required this.subject,
    this.service,
  });

  final AuthSession session;
  final ParentCurriculumSubject subject;
  final ParentCurriculumService? service;

  @override
  State<ParentCurriculumDetailView> createState() =>
      _ParentCurriculumDetailViewState();
}

class _ParentCurriculumDetailViewState extends State<ParentCurriculumDetailView> {
  late final ParentCurriculumService _service =
      widget.service ?? ParentCurriculumService();

  String _tab = 'open';
  int _termIndex = 0;
  bool _loading = true;
  String? _errorMessage;
  TeacherCurriculumWeeks? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false, String? tab}) async {
    final nextTab = tab ?? _tab;
    if (!refresh) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final data = await _service.fetchWeeks(
        widget.session,
        subjectId: widget.subject.subjectId,
        tab: nextTab,
      );
      if (!mounted) return;
      if (nextTab != 'completed' && data.isEmpty && data.summary.completed > 0) {
        await _load(refresh: true, tab: 'completed');
        return;
      }
      setState(() {
        _tab = nextTab;
        _data = data;
        _errorMessage = null;
        _loading = false;
        if (_termIndex >= data.terms.length) {
          _termIndex = 0;
        }
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
            ? 'Unable to load curriculum weeks. Please try again.'
            : _errorMessage;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.subject.title),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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

    final data = _data;
    if (data == null) {
      return const SizedBox.shrink();
    }

    final child = widget.session.selectedStudent;
    final contextLabel = data.context?.subtitle.isNotEmpty == true
        ? data.context!.subtitle
        : [
            if ((child?.title ?? '').trim().isNotEmpty) child!.title,
            if ((child?.classLabel ?? '').isNotEmpty) child!.classLabel,
          ].join(' · ');
    final summary = data.summary;
    final terms = data.terms;
    final selectedTerm =
        terms.isEmpty ? null : terms[_termIndex.clamp(0, terms.length - 1)];

    return PullToRefresh(
      color: AppColors.navy,
      onRefresh: () => _load(refresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            AppStrings.curriculumWeeks,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.context?.subjectTitle ?? widget.subject.title,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (contextLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              contextLabel,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13.5,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 14),
          _ProgressCard(summary: summary),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _TabButton(
                  tabKey: const ValueKey('parent-curriculum-tab-open'),
                  label: AppStrings.openWeeks,
                  count: summary.open,
                  selected: _tab == 'open',
                  onTap: () {
                    setState(() => _termIndex = 0);
                    _load(tab: 'open');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TabButton(
                  tabKey: const ValueKey('parent-curriculum-tab-completed'),
                  label: AppStrings.completedWeeks,
                  count: summary.completed,
                  selected: _tab == 'completed',
                  onTap: () {
                    setState(() => _termIndex = 0);
                    _load(tab: 'completed');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (terms.isEmpty)
            _EmptyWeeks(tab: _tab, message: data.emptyMessage)
          else ...[
            if (terms.length > 1) ...[
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: terms.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final term = terms[index];
                    final selected = index == _termIndex;
                    return ChoiceChip(
                      label: Text('${term.title} · ${term.count}'),
                      selected: selected,
                      onSelected: (_) => setState(() => _termIndex = index),
                      selectedColor: AppColors.highlightSoft,
                      labelStyle: TextStyle(
                        color: selected ? AppColors.navy : AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (selectedTerm != null) _TermPanel(term: selectedTerm),
            const SizedBox(height: 12),
            if (selectedTerm != null)
              for (var i = 0; i < selectedTerm.weeks.length; i++) ...[
                _WeekCard(week: selectedTerm.weeks[i]),
                if (i != selectedTerm.weeks.length - 1) const SizedBox(height: 10),
              ],
          ],
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.summary});

  final CurriculumWeekSummary summary;

  @override
  Widget build(BuildContext context) {
    final progress = (summary.progressPercent.clamp(0, 100)) / 100;

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
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.highlightSoft,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${summary.completed} ${AppStrings.weekStatusCompleted.toLowerCase()} · ${summary.open} ${AppStrings.openWeeks.toLowerCase()} · ${summary.progressPercent}%',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    this.tabKey,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final Key? tabKey;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.navy : AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: tabKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.navy : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: selected ? Colors.white24 : AppColors.highlightSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
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

class _EmptyWeeks extends StatelessWidget {
  const _EmptyWeeks({required this.tab, this.message});

  final String tab;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final completed = tab == 'completed';
    final hint = (message ?? '').trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 32, 8, 16),
      child: Column(
        children: [
          Icon(
            completed ? Icons.check_circle_outline_rounded : Icons.menu_book_outlined,
            size: 42,
            color: AppColors.muted,
          ),
          const SizedBox(height: 14),
          Text(
            completed ? AppStrings.noCompletedWeeks : AppStrings.noOpenWeeks,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hint.isNotEmpty
                ? hint
                : (completed
                    ? AppStrings.parentNoCompletedWeeksHint
                    : AppStrings.parentNoOpenWeeksHint),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _TermPanel extends StatelessWidget {
  const _TermPanel({required this.term});

  final CurriculumTerm term;

  @override
  Widget build(BuildContext context) {
    final plan = term.planText;
    final range = term.dateRange;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            term.title,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            [
              '${term.count} ${term.count == 1 ? 'slot' : 'slots'}',
              if (range.isNotEmpty) range,
            ].join(' · '),
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13,
            ),
          ),
          if (plan.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppStrings.curriculumPlanForTerm,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    plan,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.week});

  final CurriculumWeek week;

  @override
  Widget build(BuildContext context) {
    final statusColor = week.isCompleted
        ? AppColors.success
        : week.isNotCompleted
            ? AppColors.warning
            : AppColors.navy;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
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
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.highlightSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  week.weekIndexLabel,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      week.title,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (week.metaLine.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        week.metaLine,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  week.label,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            AppStrings.curriculumDetails,
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (week.hasChapterDetails)
            for (final chapter in week.chapters)
              if (chapter.hasContent) _ChapterBlock(chapter: chapter)
          else if (week.detailsText.isNotEmpty)
            _LabeledText(
              label: AppStrings.detailsLabel,
              value: week.detailsText,
            )
          else
            const Text(
              AppStrings.noWeekChapters,
              style: TextStyle(color: AppColors.muted, fontSize: 13.5),
            ),
        ],
      ),
    );
  }
}

class _ChapterBlock extends StatelessWidget {
  const _ChapterBlock({required this.chapter});

  final CurriculumChapter chapter;

  @override
  Widget build(BuildContext context) {
    final topics = chapter.topics.where((topic) => topic.hasContent).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (chapter.title.trim().isNotEmpty)
            _LabeledText(
              label: AppStrings.chapterLabel,
              value: chapter.title,
              emphasized: true,
            ),
          if (chapter.descriptionText.isNotEmpty) ...[
            const SizedBox(height: 6),
            _LabeledText(
              label: AppStrings.detailsLabel,
              value: chapter.descriptionText,
            ),
          ],
          for (final topic in topics) ...[
            const SizedBox(height: 8),
            _LabeledText(
              label: AppStrings.topicLabel,
              value: topic.title,
              emphasized: true,
              trailing: topic.isOptional ? AppStrings.optional : null,
            ),
            if (topic.descriptionText.isNotEmpty) ...[
              const SizedBox(height: 4),
              _LabeledText(
                label: AppStrings.detailsLabel,
                value: topic.descriptionText,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _LabeledText extends StatelessWidget {
  const _LabeledText({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.trailing,
  });

  final String label;
  final String value;
  final bool emphasized;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: AppColors.text,
            fontSize: emphasized ? 14 : 13.5,
            fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
            height: 1.35,
          ),
        ),
        if ((trailing ?? '').trim().isNotEmpty)
          Text(
            trailing!,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11.5,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }
}
