import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/network/api_exception.dart';
import '../../models/auth_session.dart';
import '../../models/teacher_curriculum.dart';
import '../../services/teacher_curriculum_service.dart';
import '../widgets/pull_to_refresh.dart';

class TeacherMyWeeksDetailView extends StatefulWidget {
  const TeacherMyWeeksDetailView({
    super.key,
    required this.session,
    required this.selection,
    this.service,
  });

  final AuthSession session;
  final CurriculumSubjectSelection selection;
  final TeacherCurriculumService? service;

  @override
  State<TeacherMyWeeksDetailView> createState() =>
      _TeacherMyWeeksDetailViewState();
}

class _TeacherMyWeeksDetailViewState extends State<TeacherMyWeeksDetailView> {
  late final TeacherCurriculumService _service =
      widget.service ?? TeacherCurriculumService();

  String _tab = 'open';
  int _termIndex = 0;
  bool _loading = true;
  int? _savingCompletionId;
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
        selection: widget.selection,
        tab: nextTab,
      );
      if (!mounted) return;
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

  Future<void> _updateStatus({
    required CurriculumWeek week,
    required String status,
    String? notes,
  }) async {
    setState(() => _savingCompletionId = week.completionId);
    try {
      final result = await _service.updateWeek(
        widget.session,
        completionId: week.completionId,
        status: status,
        notes: notes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? AppStrings.weekUpdated),
        ),
      );
      await _load(refresh: true);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update this week. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _savingCompletionId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.selection.subject.title),
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
      return _WeeksErrorState(
        message: _errorMessage!,
        onRetry: _load,
      );
    }

    final data = _data;
    if (data == null) {
      return const SizedBox.shrink();
    }

    final contextLabel = data.context?.subtitle ?? widget.selection.contextLabel;
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
            data.context?.subjectTitle ?? widget.selection.subject.title,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            contextLabel,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          _ProgressCard(summary: summary),
          const SizedBox(height: 14),
          _StatusTabs(
            tab: _tab,
            openCount: summary.open,
            completedCount: summary.completed,
            onChanged: (tab) {
              setState(() => _termIndex = 0);
              _load(tab: tab);
            },
          ),
          const SizedBox(height: 16),
          if (terms.isEmpty)
            _EmptyWeeks(tab: _tab)
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
            if (selectedTerm != null) _TermPanel(term: selectedTerm, tab: _tab),
            const SizedBox(height: 12),
            if (selectedTerm != null)
              for (var i = 0; i < selectedTerm.weeks.length; i++) ...[
                _WeekCard(
                  key: ValueKey<String>(
                    'week-${selectedTerm.weeks[i].completionId}-$_tab-$_termIndex',
                  ),
                  week: selectedTerm.weeks[i],
                  initiallyExpanded: _tab == 'open' && i == 0,
                  saving: _savingCompletionId == selectedTerm.weeks[i].completionId,
                  onUpdate: (status, notes) => _updateStatus(
                    week: selectedTerm.weeks[i],
                    status: status,
                    notes: notes,
                  ),
                ),
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

class _StatusTabs extends StatelessWidget {
  const _StatusTabs({
    required this.tab,
    required this.openCount,
    required this.completedCount,
    required this.onChanged,
  });

  final String tab;
  final int openCount;
  final int completedCount;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TabButton(
            tabKey: const ValueKey('my-weeks-tab-open'),
            label: AppStrings.openWeeks,
            count: openCount,
            selected: tab == 'open',
            onTap: () => onChanged('open'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _TabButton(
            tabKey: const ValueKey('my-weeks-tab-completed'),
            label: AppStrings.completedWeeks,
            count: completedCount,
            selected: tab == 'completed',
            onTap: () => onChanged('completed'),
          ),
        ),
      ],
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
  const _EmptyWeeks({required this.tab});

  final String tab;

  @override
  Widget build(BuildContext context) {
    final completed = tab == 'completed';
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
            completed ? AppStrings.noCompletedWeeksHint : AppStrings.noOpenWeeksHint,
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
  const _TermPanel({
    required this.term,
    required this.tab,
  });

  final CurriculumTerm term;
  final String tab;

  @override
  Widget build(BuildContext context) {
    final plan = term.planText;
    final range = term.dateRange;
    final statusLabel = tab == 'completed'
        ? AppStrings.completedWeeks
        : AppStrings.openWeeks;

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
              '${term.count} ${term.count == 1 ? 'week' : 'weeks'} in $statusLabel',
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

class _WeekCard extends StatefulWidget {
  const _WeekCard({
    super.key,
    required this.week,
    required this.initiallyExpanded,
    required this.saving,
    required this.onUpdate,
  });

  final CurriculumWeek week;
  final bool initiallyExpanded;
  final bool saving;
  final Future<void> Function(String status, String? notes) onUpdate;

  @override
  State<_WeekCard> createState() => _WeekCardState();
}

class _WeekCardState extends State<_WeekCard> {
  late final TextEditingController _notes =
      TextEditingController(text: widget.week.notes ?? '');

  @override
  void didUpdateWidget(covariant _WeekCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.week.notes != widget.week.notes &&
        _notes.text != (widget.week.notes ?? '')) {
      _notes.text = widget.week.notes ?? '';
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final week = widget.week;
    final statusColor = week.isCompleted
        ? AppColors.success
        : week.isNotCompleted
            ? AppColors.warning
            : AppColors.navy;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: widget.initiallyExpanded,
          tilePadding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
          title: Row(
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
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(left: 48, top: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
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
            ),
          ),
          children: [
            if (week.chapters.isEmpty)
              const Text(
                AppStrings.noWeekChapters,
                style: TextStyle(color: AppColors.muted, fontSize: 13.5),
              )
            else
              for (final chapter in week.chapters) _ChapterBlock(chapter: chapter),
            const SizedBox(height: 12),
            const Text(
              AppStrings.updateStatus,
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    key: ValueKey<String>('my-weeks-complete-${week.completionId}'),
                    onPressed: widget.saving
                        ? null
                        : () => widget.onUpdate('completed', _notes.text),
                    style: FilledButton.styleFrom(
                      backgroundColor: week.isCompleted
                          ? AppColors.success
                          : AppColors.navy,
                      foregroundColor: Colors.white,
                    ),
                    child: widget.saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(AppStrings.weekStatusCompleted),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    key: ValueKey<String>(
                      'my-weeks-not-complete-${week.completionId}',
                    ),
                    onPressed: widget.saving
                        ? null
                        : () => widget.onUpdate('not_completed', _notes.text),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: week.isNotCompleted
                          ? AppColors.warning
                          : AppColors.text,
                      side: BorderSide(
                        color: week.isNotCompleted
                            ? AppColors.warning
                            : AppColors.border,
                      ),
                    ),
                    child: const Text(AppStrings.weekStatusNotCompleted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notes,
              enabled: !widget.saving,
              decoration: const InputDecoration(
                hintText: AppStrings.weekNotesHint,
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterBlock extends StatelessWidget {
  const _ChapterBlock({required this.chapter});

  final CurriculumChapter chapter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chapter.title,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (chapter.descriptionText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              chapter.descriptionText,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 6),
          if (chapter.topics.isEmpty)
            const Text(
              AppStrings.noWeekTopics,
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            )
          else
            for (final topic in chapter.topics)
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(Icons.circle, size: 6, color: AppColors.navy),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                topic.title,
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (topic.isOptional)
                                const Text(
                                  AppStrings.optional,
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 11.5,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                          if (topic.descriptionText.isNotEmpty)
                            Text(
                              topic.descriptionText,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12.5,
                                height: 1.35,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _WeeksErrorState extends StatelessWidget {
  const _WeeksErrorState({
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
