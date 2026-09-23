import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/network/api_exception.dart';
import '../../models/auth_session.dart';
import '../../models/teacher_class_attendance.dart';
import '../../services/teacher_class_attendance_service.dart';
import '../widgets/pull_to_refresh.dart';

class TeacherClassAttendanceMarkView extends StatefulWidget {
  const TeacherClassAttendanceMarkView({
    super.key,
    required this.session,
    required this.classItem,
    required this.section,
    this.service,
    this.clock,
  });

  final AuthSession session;
  final ClassAttendanceClass classItem;
  final ClassAttendanceSection section;
  final TeacherClassAttendanceService? service;
  final DateTime Function()? clock;

  @override
  State<TeacherClassAttendanceMarkView> createState() =>
      _TeacherClassAttendanceMarkViewState();
}

class _TeacherClassAttendanceMarkViewState extends State<TeacherClassAttendanceMarkView> {
  late final TeacherClassAttendanceService _service =
      widget.service ?? TeacherClassAttendanceService();
  late String _date;
  bool _loading = true;
  bool _saving = false;
  String? _errorMessage;
  TeacherClassAttendanceMark? _data;
  List<ClassAttendanceStudent> _students = const [];

  DateTime get _now => widget.clock?.call() ?? DateTime.now();

  static const _fallbackStatuses = [
    ClassAttendanceStatusOption(key: 'present', label: 'Present'),
    ClassAttendanceStatusOption(key: 'absent', label: 'Absent'),
    ClassAttendanceStatusOption(key: 'late', label: 'Late'),
    ClassAttendanceStatusOption(key: 'leave', label: 'Leave'),
  ];

  @override
  void initState() {
    super.initState();
    _date = isoClassAttendanceDate(_now);
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
      final data = await _service.fetchMark(
        widget.session,
        classItem: widget.classItem,
        section: widget.section,
        date: _date,
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _students = data.students;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load students. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final current = DateTime.tryParse(_date) ?? _now;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(_now.year - 1),
      lastDate: DateTime(_now.year + 1, 12, 31),
    );
    if (picked == null) return;
    final next = isoClassAttendanceDate(picked);
    if (next == _date) return;
    setState(() => _date = next);
    await _load();
  }

  void _setStatus(ClassAttendanceStudent student, String status) {
    if (student.locked || _data?.canMark == false || _saving) return;
    setState(() {
      _students = [
        for (final item in _students)
          if (item.id == student.id) item.copyWithStatus(status) else item,
      ];
    });
  }

  void _setAll(String status) {
    if (_data?.canMark == false || _saving) return;
    setState(() {
      _students = [
        for (final item in _students)
          if (item.locked) item else item.copyWithStatus(status),
      ];
    });
  }

  Future<void> _save() async {
    if (_saving || _students.isEmpty || _data?.canMark == false) return;
    setState(() => _saving = true);
    try {
      final result = await _service.save(
        widget.session,
        classItem: widget.classItem,
        section: widget.section,
        date: _date,
        students: _students,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.navy,
          content: Text(result.message ?? 'Attendance saved.'),
        ),
      );
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save attendance. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _data?.heading ?? '${widget.classItem.title} — ${widget.section.displayName}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
      ),
      body: _buildBody(),
      bottomNavigationBar: _data == null || !(_data?.canMark ?? true)
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton(
                  onPressed: _saving || _loading || _students.isEmpty ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(
                    _saving
                        ? 'Saving…'
                        : ((_data?.alreadyMarked ?? false)
                            ? AppStrings.updateAttendance
                            : AppStrings.saveAttendance),
                  ),
                ),
              ),
            ),
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
              const Icon(Icons.wifi_off_rounded, size: 42, color: AppColors.muted),
              const SizedBox(height: 14),
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
    final heading = data?.heading ?? '${widget.classItem.title} — ${widget.section.displayName}';
    final statuses = (data?.statuses.isNotEmpty ?? false) ? data!.statuses : _fallbackStatuses;
    final subtitle = [
      data?.sessionName ?? widget.classItem.sessionLabel,
      '${_students.length} student${_students.length == 1 ? '' : 's'}',
    ].where((part) => part.trim().isNotEmpty).join(' · ');

    return PullToRefresh(
      color: AppColors.navy,
      onRefresh: () => _load(refresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
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
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13.5,
              height: 1.35,
            ),
          ),
        ],
        const SizedBox(height: 16),
        _DateField(
          value: displayClassAttendanceDate(_date),
          loading: _loading,
          onTap: _saving ? null : _pickDate,
        ),
        if (data?.blockMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.errorSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              data!.blockMessage!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        if ((data?.canMark ?? true) && _students.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: _saving ? null : () => _setAll('present'),
                child: const Text(AppStrings.markAllPresent),
              ),
              OutlinedButton(
                onPressed: _saving ? null : () => _setAll('absent'),
                child: const Text(AppStrings.markAllAbsent),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        if (_students.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Text(
              AppStrings.noClassAttendanceStudents,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 15, height: 1.4),
            ),
          )
        else
          for (var i = 0; i < _students.length; i++) ...[
            _StudentCard(
              index: i + 1,
              student: _students[i],
              statuses: statuses,
              enabled: (data?.canMark ?? true) && !_saving,
              onStatus: (status) => _setStatus(_students[i], status),
            ),
            if (i != _students.length - 1) const SizedBox(height: 10),
          ],
      ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.value,
    required this.onTap,
    this.loading = false,
  });

  final String value;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          AppStrings.attendanceDate,
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (loading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.navy,
                      ),
                    )
                  else
                    const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.muted),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.index,
    required this.student,
    required this.statuses,
    required this.enabled,
    required this.onStatus,
  });

  final int index;
  final ClassAttendanceStudent student;
  final List<ClassAttendanceStatusOption> statuses;
  final bool enabled;
  final ValueChanged<String> onStatus;

  @override
  Widget build(BuildContext context) {
    final canEdit = enabled && !student.locked;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
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
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.highlightSoft,
                backgroundImage: student.photoUrl == null ? null : NetworkImage(student.photoUrl!),
                child: student.photoUrl == null
                    ? Text(
                        student.initials,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$index. ${student.displayName}',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (student.displayRoll.isNotEmpty) 'Roll ${student.displayRoll}',
                        if ((student.fatherName ?? '').trim().isNotEmpty) 'Father: ${student.fatherName}',
                      ].join(' · '),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12.5,
                      ),
                    ),
                    if (student.locked)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          AppStrings.markedLateByManagement,
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final status in statuses)
                _StatusPill(
                  label: status.label,
                  selected: student.status == status.key,
                  enabled: canEdit,
                  color: _statusColor(status.key),
                  onTap: () => onStatus(status.key),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: 0.16) : AppColors.background,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? color : AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? color : AppColors.muted,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

Color _statusColor(String key) {
  switch (key) {
    case 'present':
      return const Color(0xFF047857);
    case 'absent':
      return const Color(0xFFB91C1C);
    case 'late':
      return const Color(0xFFC2410C);
    case 'leave':
      return const Color(0xFF1D4ED8);
    default:
      return AppColors.navy;
  }
}
