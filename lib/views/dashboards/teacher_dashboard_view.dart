import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/network/api_exception.dart';
import '../../models/auth_session.dart';
import '../../models/teacher_attendance.dart';
import '../../models/teacher_timetable.dart';
import '../../services/teacher_attendance_service.dart';
import '../../services/teacher_timetable_service.dart';
import 'dashboard_shell.dart';

const _teacherFeatureActions = [
  DashboardAction(
    icon: Icons.calendar_month_rounded,
    label: AppStrings.myTimetable,
    route: AppRoutes.teacherTimetable,
  ),
  DashboardAction(
    icon: Icons.event_available_rounded,
    label: AppStrings.myAttendance,
    route: AppRoutes.teacherAttendance,
  ),
  DashboardAction(
    icon: Icons.how_to_reg_rounded,
    label: AppStrings.classAttendance,
    route: AppRoutes.teacherClassAttendance,
  ),
  DashboardAction(
    icon: Icons.menu_book_rounded,
    label: AppStrings.dailyDiary,
    route: AppRoutes.teacherDailyDiary,
  ),
  DashboardAction(
    icon: Icons.chat_bubble_outline_rounded,
    label: AppStrings.specialRemarks,
    route: AppRoutes.teacherSpecialRemarks,
  ),
  DashboardAction(
    icon: Icons.quiz_rounded,
    label: AppStrings.exams,
    route: AppRoutes.teacherExams,
  ),
  DashboardAction(
    icon: Icons.edit_note_rounded,
    label: AppStrings.testsAndHw,
    route: AppRoutes.teacherTestsHw,
  ),
];

class TeacherDashboardView extends StatefulWidget {
  const TeacherDashboardView({
    super.key,
    required this.session,
    this.attendanceService,
    this.timetableService,
    this.clock,
  });

  final AuthSession session;
  final TeacherAttendanceService? attendanceService;
  final TeacherTimetableService? timetableService;
  final DateTime Function()? clock;

  @visibleForTesting
  static TeacherAttendanceService? debugAttendanceService;

  @visibleForTesting
  static TeacherTimetableService? debugTimetableService;

  @override
  State<TeacherDashboardView> createState() => _TeacherDashboardViewState();
}

class _TeacherDashboardViewState extends State<TeacherDashboardView> {
  bool _attendanceLoading = true;
  bool _timetableLoading = true;
  String? _attendanceError;
  String? _timetableError;
  TeacherAttendanceSummary _summary = const TeacherAttendanceSummary();
  PeriodFocus? _periodFocus;

  TeacherAttendanceService get _attendance =>
      widget.attendanceService ??
      TeacherDashboardView.debugAttendanceService ??
      TeacherAttendanceService();

  TeacherTimetableService get _timetable =>
      widget.timetableService ??
      TeacherDashboardView.debugTimetableService ??
      TeacherTimetableService();

  DateTime get _now => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    await Future.wait([
      _loadAttendance(refresh: refresh),
      _loadTimetable(refresh: refresh),
    ]);
  }

  Future<void> _loadAttendance({bool refresh = false}) async {
    if (!refresh) {
      if (!_attendanceLoading) {
        setState(() {
          _attendanceLoading = true;
          _attendanceError = null;
        });
      } else {
        _attendanceError = null;
      }
    }

    try {
      final data = await _attendance.fetch(
        widget.session,
        query: const TeacherAttendanceQuery(page: 1, perPage: 1),
      );
      if (!mounted) return;
      setState(() {
        _summary = data.summary;
        _attendanceError = null;
        _attendanceLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _attendanceError = error.message;
        _attendanceLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _attendanceError = 'Unable to load your attendance. Please try again.';
        _attendanceLoading = false;
      });
    }
  }

  Future<void> _loadTimetable({bool refresh = false}) async {
    if (!refresh) {
      if (!_timetableLoading) {
        setState(() {
          _timetableLoading = true;
          _timetableError = null;
        });
      } else {
        _timetableError = null;
      }
    }

    try {
      final data = await _timetable.fetch(widget.session);
      if (!mounted) return;
      setState(() {
        _periodFocus = data.focusForNow(_now);
        _timetableError = null;
        _timetableLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _timetableError = error.message;
        _timetableLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _timetableError = 'Unable to load your timetable. Please try again.';
        _timetableLoading = false;
      });
    }
  }

  void _openAttendance() {
    Navigator.of(context).pushNamed(
      AppRoutes.teacherAttendance,
      arguments: widget.session,
    );
  }

  void _openTimetable() {
    Navigator.of(context).pushNamed(
      AppRoutes.teacherTimetable,
      arguments: widget.session,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      session: widget.session,
      onRefresh: () => _load(refresh: true),
      homeContent: Column(
        children: [
          _AttendanceStatusCard(
            loading: _attendanceLoading,
            errorMessage: _attendanceError,
            summary: _summary,
            onRetry: _loadAttendance,
            onOpen: _openAttendance,
          ),
          const SizedBox(height: 14),
          _UpcomingPeriodCard(
            loading: _timetableLoading,
            errorMessage: _timetableError,
            focus: _periodFocus,
            onRetry: _loadTimetable,
            onOpen: _openTimetable,
          ),
        ],
      ),
      homeActions: _teacherFeatureActions,
      actions: const [
        ..._teacherFeatureActions,
        DashboardAction(
          icon: Icons.groups_rounded,
          label: 'Student Info',
        ),
        DashboardAction(
          icon: Icons.lock_reset_rounded,
          label: AppStrings.changePassword,
          route: AppRoutes.changePassword,
        ),
      ],
    );
  }
}

class _AttendanceStatusCard extends StatelessWidget {
  const _AttendanceStatusCard({
    required this.loading,
    required this.errorMessage,
    required this.summary,
    required this.onRetry,
    required this.onOpen,
  });

  final bool loading;
  final String? errorMessage;
  final TeacherAttendanceSummary summary;
  final VoidCallback onRetry;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: loading || errorMessage != null ? null : onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
            child: loading
                ? const SizedBox(
                    height: 72,
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.navy),
                    ),
                  )
                : errorMessage != null
                    ? _ErrorBody(message: errorMessage!, onRetry: onRetry)
                    : _StatusBody(summary: summary),
          ),
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          AppStrings.todaysAttendance,
          style: TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          message,
          style: const TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onRetry,
          child: const Text(AppStrings.retry),
        ),
      ],
    );
  }
}

class _StatusBody extends StatelessWidget {
  const _StatusBody({required this.summary});

  final TeacherAttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final today = summary.today;
    final month = summary.month;
    final statusLabel = today == null
        ? AppStrings.notMarked
        : ((today.statusLabel ?? today.status)?.trim().isNotEmpty == true
            ? (today.statusLabel ?? today.status)!.trim()
            : AppStrings.notMarked);
    final style = AttendanceStatusStyle.of(today?.status);
    final inTime = today?.inTimeLabel?.trim();
    final outTime = today?.outTimeLabel?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                AppStrings.todaysAttendance,
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: style.background,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(
              color: style.foreground,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
        if ((inTime != null && inTime.isNotEmpty) ||
            (outTime != null && outTime.isNotEmpty)) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TimeLine(
                  label: AppStrings.inTime,
                  value: (inTime == null || inTime.isEmpty) ? '—' : inTime,
                ),
              ),
              Expanded(
                child: _TimeLine(
                  label: AppStrings.outTime,
                  value: (outTime == null || outTime.isEmpty) ? '—' : outTime,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        const Text(
          AppStrings.thisMonth,
          style: TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _MonthStat(label: AppStrings.presentMonth, value: month.present)),
            Expanded(child: _MonthStat(label: AppStrings.absentMonth, value: month.absent)),
            Expanded(child: _MonthStat(label: AppStrings.lateMonth, value: month.late)),
            Expanded(child: _MonthStat(label: AppStrings.leaveMonth, value: month.leave)),
          ],
        ),
      ],
    );
  }
}

class _TimeLine extends StatelessWidget {
  const _TimeLine({required this.label, required this.value});

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
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
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
            fontSize: 16,
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

class _UpcomingPeriodCard extends StatelessWidget {
  const _UpcomingPeriodCard({
    required this.loading,
    required this.errorMessage,
    required this.focus,
    required this.onRetry,
    required this.onOpen,
  });

  final bool loading;
  final String? errorMessage;
  final PeriodFocus? focus;
  final VoidCallback onRetry;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: loading || errorMessage != null ? null : onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
            child: loading
                ? const SizedBox(
                    height: 72,
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.navy),
                    ),
                  )
                : errorMessage != null
                    ? _PeriodErrorBody(message: errorMessage!, onRetry: onRetry)
                    : _PeriodBody(focus: focus),
          ),
        ),
      ),
    );
  }
}

class _PeriodErrorBody extends StatelessWidget {
  const _PeriodErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          AppStrings.upcomingPeriod,
          style: TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          message,
          style: const TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onRetry,
          child: const Text(AppStrings.retry),
        ),
      ],
    );
  }
}

class _PeriodBody extends StatelessWidget {
  const _PeriodBody({required this.focus});

  final PeriodFocus? focus;

  @override
  Widget build(BuildContext context) {
    final cell = focus?.cell;
    final badge = focus?.kind == PeriodFocusKind.now
        ? AppStrings.periodNow
        : AppStrings.periodUpNext;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                AppStrings.upcomingPeriod,
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
        const SizedBox(height: 10),
        if (cell == null)
          const Text(
            AppStrings.noUpcomingPeriod,
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          )
        else ...[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.highlightSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cell.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              if (cell.timeRange.isNotEmpty)
                Text(
                  cell.timeRange,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (cell.isFree)
            const Text(
              AppStrings.freePeriod,
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            for (var i = 0; i < cell.lessons.length; i++) ...[
              if (i > 0) const SizedBox(height: 6),
              Text(
                cell.lessons[i].title,
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              if (cell.lessons[i].subtitle.isNotEmpty)
                Text(
                  cell.lessons[i].subtitle,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
            ],
        ],
      ],
    );
  }
}
