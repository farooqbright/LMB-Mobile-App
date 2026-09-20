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

          return RefreshIndicator(
            color: AppColors.navy,
            onRefresh: () => _controller.load(refresh: true),
            child: ListView(
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
                  period: _controller.period,
                  dateFrom: _controller.dateFrom,
                  dateTo: _controller.dateTo,
                  onPeriodSelected: _controller.selectPeriod,
                  onPickFrom: () => _pickDate(from: true),
                  onPickTo: () => _pickDate(from: false),
                  onApply: _controller.applyFilters,
                  onReset: _controller.resetFilters,
                ),
                const SizedBox(height: 12),
                _RecordsSection(
                  title: AppStrings.attendanceDetails,
                  subtitle: _controller.rangeLabel,
                  records: data.records,
                ),
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

class _RecordsSection extends StatelessWidget {
  const _RecordsSection({
    required this.title,
    required this.subtitle,
    required this.records,
  });

  final String title;
  final String subtitle;
  final List<ParentAttendanceRecord> records;

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
          Text(
            title,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          if (records.isEmpty)
            const Text(
              AppStrings.noAttendance,
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            for (var i = 0; i < records.length; i++) ...[
              if (i > 0) const Divider(height: 18),
              _RecordRow(record: records[i]),
            ],
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.record});

  final ParentAttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final style = AttendanceStatusStyle.of(record.status);

    return Row(
      children: [
        Expanded(
          child: Text(
            record.displayDate,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
              fontSize: 14,
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
    required this.period,
    required this.dateFrom,
    required this.dateTo,
    required this.onPeriodSelected,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onApply,
    required this.onReset,
  });

  final ParentAttendancePeriod period;
  final DateTime dateFrom;
  final DateTime dateTo;
  final ValueChanged<ParentAttendancePeriod> onPeriodSelected;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback onApply;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final isCustom = period == ParentAttendancePeriod.custom;

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
            AppStrings.quickFilters,
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PeriodChip(
                label: AppStrings.thisMonth,
                selected: period == ParentAttendancePeriod.month,
                onTap: () => onPeriodSelected(ParentAttendancePeriod.month),
              ),
              _PeriodChip(
                label: AppStrings.lastWeek,
                selected: period == ParentAttendancePeriod.lastWeek,
                onTap: () => onPeriodSelected(ParentAttendancePeriod.lastWeek),
              ),
              _PeriodChip(
                label: AppStrings.lastMonth,
                selected: period == ParentAttendancePeriod.lastMonth,
                onTap: () => onPeriodSelected(ParentAttendancePeriod.lastMonth),
              ),
              _PeriodChip(
                label: AppStrings.betweenDates,
                selected: isCustom,
                onTap: () => onPeriodSelected(ParentAttendancePeriod.custom),
              ),
            ],
          ),
          if (isCustom) ...[
            const SizedBox(height: 12),
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
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: OutlinedButton(
                      onPressed: onReset,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.text,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text(AppStrings.reset),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: FilledButton(
                      onPressed: onApply,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text(AppStrings.apply),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.navy : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? AppColors.navy : AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.text,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
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

