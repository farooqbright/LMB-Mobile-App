import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/auth_session.dart';
import '../../models/teacher_attendance.dart';
import '../controllers/parent_attendance_controller.dart';
import '../models/parent_attendance.dart';
import '../services/parent_attendance_service.dart';

class ParentAttendanceView extends StatefulWidget {
  const ParentAttendanceView({
    super.key,
    required this.session,
    this.service,
    this.clock,
  });

  final AuthSession session;
  final ParentAttendanceService? service;
  final DateTime Function()? clock;

  @override
  State<ParentAttendanceView> createState() => _ParentAttendanceViewState();
}

class _ParentAttendanceViewState extends State<ParentAttendanceView> {
  late final ParentAttendanceController _controller = ParentAttendanceController(
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
    await _controller.applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.attendance),
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
            return ListView(
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
            );
          }

          final data = _controller.data ?? const ParentAttendanceData();
          final child = widget.session.selectedStudent;
          final studentName = (data.studentName ?? child?.title)?.trim();
          final classLabel = data.classLabel.isNotEmpty
              ? data.classLabel
              : (child?.classLabel ?? '');
          final branchName = (data.branchName ?? child?.branchName)?.trim() ?? '';
          final statuses = data.statuses.isNotEmpty ? data.statuses : _fallbackStatuses;

          return RefreshIndicator(
            color: AppColors.navy,
            onRefresh: () => _controller.load(refresh: true),
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _StudentHeader(
                  name: (studentName == null || studentName.isEmpty)
                      ? AppStrings.attendance
                      : studentName,
                  classLabel: classLabel,
                  branchName: branchName,
                ),
                const SizedBox(height: 12),
                _TodayStatusCard(summary: data.summary),
                const SizedBox(height: 12),
                _LastMonthCard(
                  label: data.lastMonthLabel,
                  counts: data.summary.lastMonth,
                ),
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
                  onAllHistory: _controller.showAllHistory,
                ),
                const SizedBox(height: 18),
                const Text(
                  AppStrings.attendanceHistory,
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                if (data.isEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(8, 24, 8, 8),
                    child: Text(
                      AppStrings.noAttendance,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  for (var i = 0; i < data.records.length; i++) ...[
                    _RecordCard(record: data.records[i]),
                    if (i != data.records.length - 1) const SizedBox(height: 10),
                  ],
                if (_controller.loadingMore) ...[
                  const SizedBox(height: 16),
                  const Center(
                    child: CircularProgressIndicator(color: AppColors.navy),
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

class _StudentHeader extends StatelessWidget {
  const _StudentHeader({
    required this.name,
    required this.classLabel,
    required this.branchName,
  });

  final String name;
  final String classLabel;
  final String branchName;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (classLabel.isNotEmpty) classLabel,
      if (branchName.isNotEmpty) branchName,
    ].join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
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
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TodayStatusCard extends StatelessWidget {
  const _TodayStatusCard({required this.summary});

  final ParentAttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final today = summary.today;
    final statusLabel = today == null
        ? AppStrings.notMarked
        : ((today.statusLabel ?? today.status)?.trim().isNotEmpty == true
            ? (today.statusLabel ?? today.status)!.trim()
            : AppStrings.notMarked);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              AppStrings.todaysAttendance,
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
          _StatusBadge(
            status: today?.status,
            label: statusLabel,
          ),
        ],
      ),
    );
  }
}

class _LastMonthCard extends StatelessWidget {
  const _LastMonthCard({
    required this.counts,
    this.label,
  });

  final AttendanceMonthCounts counts;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
              const Text(
                AppStrings.lastMonth,
                style: TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              if ((label ?? '').trim().isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _MonthStat(label: AppStrings.presentMonth, value: counts.present)),
              Expanded(child: _MonthStat(label: AppStrings.absentMonth, value: counts.absent)),
              Expanded(child: _MonthStat(label: AppStrings.lateMonth, value: counts.late)),
              Expanded(child: _MonthStat(label: AppStrings.leaveMonth, value: counts.leave)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthStat extends StatelessWidget {
  const _MonthStat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.label});

  final String? status;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final style = AttendanceStatusStyle.of(status);
    final text = (label ?? '').trim().isNotEmpty ? label!.trim() : AppStrings.notMarked;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: style.foreground,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
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
    required this.onAllHistory,
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
  final VoidCallback onAllHistory;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppStrings.filter,
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
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
          const SizedBox(height: 8),
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
                  child: const Text(AppStrings.apply),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              TextButton(
                onPressed: onAllHistory,
                child: const Text(AppStrings.allHistory),
              ),
              if (hasActiveFilters)
                TextButton(
                  onPressed: onClear,
                  child: const Text(AppStrings.clearFilters),
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
  const _RecordCard({required this.record});

  final ParentAttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final style = AttendanceStatusStyle.of(record.status);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              record.displayDate,
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: style.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              record.displayStatus,
              style: TextStyle(
                color: style.foreground,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
