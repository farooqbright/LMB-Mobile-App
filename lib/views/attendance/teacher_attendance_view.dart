import 'package:flutter/material.dart';

import '../../controllers/teacher_attendance_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/auth_session.dart';
import '../../models/teacher_attendance.dart';
import '../../services/teacher_attendance_service.dart';

class TeacherAttendanceView extends StatefulWidget {
  const TeacherAttendanceView({
    super.key,
    required this.session,
    this.service,
    this.clock,
  });

  final AuthSession session;
  final TeacherAttendanceService? service;
  final DateTime Function()? clock;

  @override
  State<TeacherAttendanceView> createState() => _TeacherAttendanceViewState();
}

class _TeacherAttendanceViewState extends State<TeacherAttendanceView> {
  late final TeacherAttendanceController _controller = TeacherAttendanceController(
    session: widget.session,
    service: widget.service,
    clock: widget.clock,
  );
  final _scrollController = ScrollController();

  static const _fallbackStatuses = [
    AttendanceStatusOption(key: 'present', label: 'Present'),
    AttendanceStatusOption(key: 'absent', label: 'Absent'),
    AttendanceStatusOption(key: 'late', label: 'Late'),
    AttendanceStatusOption(key: 'leave', label: 'Leave'),
    AttendanceStatusOption(key: 'short_leave', label: 'Short Leave'),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _controller.load();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      _controller.loadMore();
    }
  }

  Future<void> _pickDate({required bool from}) async {
    final initial = from ? _controller.dateFrom : _controller.dateTo;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(_controller.now.year - 2),
      lastDate: DateTime(_controller.now.year + 1, 12, 31),
    );
    if (picked == null) return;
    if (from) {
      _controller.setDateFrom(picked);
    } else {
      _controller.setDateTo(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.myAttendance),
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
          final summary = data?.summary ?? const TeacherAttendanceSummary();
          final statuses = (data?.statuses.isNotEmpty ?? false)
              ? data!.statuses
              : _fallbackStatuses;

          return RefreshIndicator(
            color: AppColors.navy,
            onRefresh: () => _controller.load(refresh: true),
            child: ListView(
              key: const PageStorageKey<String>('teacher-attendance-list'),
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _SummaryGrid(summary: summary),
                const SizedBox(height: 12),
                _FilterCard(
                  status: _controller.status,
                  statuses: statuses,
                  dateFrom: _controller.dateFrom,
                  dateTo: _controller.dateTo,
                  hasActiveFilters: _controller.hasActiveFilters,
                  onStatusChanged: _controller.setStatus,
                  onPickFrom: () => _pickDate(from: true),
                  onPickTo: () => _pickDate(from: false),
                  onApply: _controller.applyFilters,
                  onClear: _controller.clearFilters,
                ),
                const SizedBox(height: 12),
                if (data == null || data.isEmpty)
                  const _EmptyRecords()
                else
                  for (var i = 0; i < data.records.length; i++) ...[
                    _RecordCard(record: data.records[i]),
                    if (i != data.records.length - 1) const SizedBox(height: 10),
                  ],
                if (_controller.hasMore || _controller.loadingMore) ...[
                  const SizedBox(height: 16),
                  _LoadMore(
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

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});

  final TeacherAttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final month = summary.month;
    final items = [
      _StatItem(
        label: AppStrings.attendanceToday,
        wide: true,
        child: summary.today == null
            ? const Text(
                AppStrings.notMarked,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              )
            : _StatusBadge(
                status: summary.today!.status,
                label: summary.today!.statusLabel ?? summary.today!.status,
              ),
      ),
      _StatItem(label: AppStrings.totalDaysMonth, value: '${month.total}'),
      _StatItem(label: AppStrings.presentMonth, value: '${month.present}'),
      _StatItem(label: AppStrings.absentMonth, value: '${month.absent}'),
      _StatItem(label: AppStrings.lateMonth, value: '${month.late}'),
      _StatItem(label: AppStrings.leaveMonth, value: '${month.leave}'),
      _StatItem(label: AppStrings.shortLeaveMonth, value: '${month.shortLeave}'),
    ];

    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return SizedBox(
            width: item.wide ? 118 : 78,
            child: _StatCard(item: item),
          );
        },
      ),
    );
  }
}

class _StatItem {
  const _StatItem({
    required this.label,
    this.value,
    this.child,
    this.wide = false,
  });

  final String label;
  final String? value;
  final Widget? child;
  final bool wide;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.item});

  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const Spacer(),
          item.child ??
              Text(
                item.value ?? '0',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
        ],
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.status,
    required this.statuses,
    required this.dateFrom,
    required this.dateTo,
    required this.hasActiveFilters,
    required this.onStatusChanged,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onApply,
    required this.onClear,
  });

  final String? status;
  final List<AttendanceStatusOption> statuses;
  final DateTime dateFrom;
  final DateTime dateTo;
  final bool hasActiveFilters;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback onApply;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _CompactField(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: status,
                      isDense: true,
                      isExpanded: true,
                      hint: const Text(
                        AppStrings.allStatuses,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text(AppStrings.allStatuses),
                        ),
                        for (final option in statuses)
                          if (option.key.isNotEmpty)
                            DropdownMenuItem<String?>(
                              value: option.key,
                              child: Text(option.label),
                            ),
                      ],
                      onChanged: onStatusChanged,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                height: 36,
                child: FilledButton(
                  onPressed: onApply,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(AppStrings.filter),
                ),
              ),
              if (hasActiveFilters)
                IconButton(
                  onPressed: onClear,
                  tooltip: AppStrings.clearFilters,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.muted),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: AppStrings.fromDate,
                  value: displayAttendanceDate(dateFrom),
                  onTap: onPickFrom,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _DateField(
                  label: AppStrings.toDate,
                  value: displayAttendanceDate(dateTo),
                  onTap: onPickTo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactField extends StatelessWidget {
  const _CompactField({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ),
              const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.record,
  });

  final TeacherAttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.displayDate,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    if (record.displayBranch.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        record.displayBranch,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _StatusBadge(status: record.status, label: record.displayStatus),
              if (record.secondaryStatus != null) ...[
                const SizedBox(width: 6),
                _StatusBadge(
                  status: record.secondaryStatus,
                  label: record.secondaryStatusLabel ?? record.secondaryStatus,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _MetaLine(label: AppStrings.inTime, value: record.displayIn)),
              Expanded(child: _MetaLine(label: AppStrings.outTime, value: record.displayOut)),
              Expanded(flex: 2, child: _MetaLine(label: AppStrings.markedBy, value: record.displayMarkedBy)),
            ],
          ),
          const SizedBox(height: 8),
          _MetaLine(label: AppStrings.remarks, value: record.displayRemarks),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
    required this.label,
  });

  final String? status;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final style = AttendanceStatusStyle.of(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        (label ?? '').trim().isEmpty ? '—' : label!.trim(),
        style: TextStyle(
          color: style.foreground,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _LoadMore extends StatelessWidget {
  const _LoadMore({
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

class _EmptyRecords extends StatelessWidget {
  const _EmptyRecords();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(12, 36, 12, 24),
      child: Column(
        children: [
          Icon(Icons.event_busy_rounded, size: 42, color: AppColors.muted),
          SizedBox(height: 12),
          Text(
            AppStrings.noAttendance,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            AppStrings.noAttendanceHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
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
