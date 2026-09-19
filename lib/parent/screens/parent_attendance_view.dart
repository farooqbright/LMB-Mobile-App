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
                _SummaryGrid(summary: data.summary),
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

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});

  final ParentAttendanceSummary summary;

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
