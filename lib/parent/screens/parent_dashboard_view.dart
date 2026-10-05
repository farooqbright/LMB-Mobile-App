import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/network/api_exception.dart';
import '../../models/auth_session.dart';
import '../../models/school_announcement.dart';
import '../../models/teacher_attendance.dart';
import '../../services/announcement_service.dart';
import '../../services/auth_service.dart';
import '../../services/session_store.dart';
import '../../views/dashboards/dashboard_shell.dart';
import '../../widgets/announcements_banner.dart';
import '../models/parent_attendance.dart';
import '../services/parent_attendance_service.dart';

const _parentFeatureActions = [
  DashboardAction(
    icon: Icons.fact_check_outlined,
    label: AppStrings.attendance,
    route: AppRoutes.parentAttendance,
  ),
  DashboardAction(
    icon: Icons.menu_book_outlined,
    label: AppStrings.dailyDiary,
    route: AppRoutes.parentDailyDiary,
  ),
  DashboardAction(
    icon: Icons.chat_bubble_outline_rounded,
    label: AppStrings.specialRemarks,
    route: AppRoutes.parentSpecialRemarks,
  ),
  DashboardAction(
    icon: Icons.receipt_long_outlined,
    label: AppStrings.feeVouchers,
    route: AppRoutes.parentFeeVouchers,
  ),
  DashboardAction(
    icon: Icons.calendar_month_outlined,
    label: AppStrings.timeTable,
    route: AppRoutes.parentTimetable,
  ),
  DashboardAction(
    icon: Icons.emoji_events_outlined,
    label: AppStrings.results,
    route: AppRoutes.parentResults,
  ),
  DashboardAction(
    icon: Icons.event_note_outlined,
    label: AppStrings.datesheet,
    route: AppRoutes.parentDatesheet,
  ),
];

List<DashboardAction> _parentActionsFor(AuthSession session) {
  return [
    for (final action in _parentFeatureActions)
      if (action.route != AppRoutes.parentFeeVouchers ||
          session.showParentFeeVouchers)
        action,
  ];
}

class ParentDashboardView extends StatefulWidget {
  const ParentDashboardView({
    super.key,
    required this.session,
    this.attendanceService,
    this.announcementService,
    this.authService,
  });

  final AuthSession session;
  final ParentAttendanceService? attendanceService;
  final AnnouncementService? announcementService;
  final AuthService? authService;

  @visibleForTesting
  static ParentAttendanceService? debugAttendanceService;

  @visibleForTesting
  static AnnouncementService? debugAnnouncementService;

  @override
  State<ParentDashboardView> createState() => _ParentDashboardViewState();
}

class _ParentDashboardViewState extends State<ParentDashboardView> {
  late AuthSession _session = widget.session;
  bool _loading = true;
  bool _announcementsLoading = true;
  String? _errorMessage;
  String? _announcementsError;
  ParentAttendanceSummary _summary = const ParentAttendanceSummary();
  List<SchoolAnnouncement> _announcements = const [];

  ParentAttendanceService get _attendance =>
      widget.attendanceService ??
      ParentDashboardView.debugAttendanceService ??
      ParentAttendanceService();

  AnnouncementService get _announcementsApi =>
      widget.announcementService ??
      ParentDashboardView.debugAnnouncementService ??
      AnnouncementService();

  AuthService get _auth => widget.authService ?? AuthService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _refreshSession() async {
    try {
      final next = await _auth.refreshSession(_session);
      await SessionStore.instance.update(next);
      if (!mounted) return;
      setState(() => _session = next);
    } catch (_) {}
  }

  Future<void> _load({bool refresh = false}) async {
    await _refreshSession();
    await Future.wait([
      _loadAnnouncements(refresh: refresh),
      _loadAttendance(refresh: refresh),
    ]);
  }

  Future<void> _loadAnnouncements({bool refresh = false}) async {
    if (!refresh) {
      if (!_announcementsLoading) {
        setState(() {
          _announcementsLoading = true;
          _announcementsError = null;
        });
      } else {
        _announcementsError = null;
      }
    }

    try {
      final rows = await _announcementsApi.fetchForParent(_session);
      if (!mounted) return;
      setState(() {
        _announcements = rows;
        _announcementsError = null;
        _announcementsLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _announcementsError = error.message;
        _announcementsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _announcementsError = 'Unable to load announcements. Please try again.';
        _announcementsLoading = false;
      });
    }
  }

  Future<void> _loadAttendance({bool refresh = false}) async {
    if (!refresh) {
      if (!_loading) {
        setState(() {
          _loading = true;
          _errorMessage = null;
        });
      } else {
        _errorMessage = null;
      }
    }

    try {
      final data = await _attendance.fetch(
        _session,
        query: const ParentAttendanceQuery(page: 1, perPage: 1),
      );
      if (!mounted) return;
      setState(() {
        _summary = data.summary;
        _errorMessage = null;
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
        _errorMessage = 'Unable to load attendance. Please try again.';
        _loading = false;
      });
    }
  }

  void _openAttendance() {
    Navigator.of(context).pushNamed(
      AppRoutes.parentAttendance,
      arguments: _session,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _session.parentProfile;
    final child = _session.selectedStudent;
    final actions = _parentActionsFor(_session);

    return DashboardShell(
      session: _session,
      onRefresh: () => _load(refresh: true),
      homeContent: Column(
        children: [
          AnnouncementsBanner(
            loading: _announcementsLoading,
            errorMessage: _announcementsError,
            announcements: _announcements,
            onRetry: _loadAnnouncements,
          ),
          if (_announcementsLoading ||
              _announcementsError != null ||
              _announcements.isNotEmpty)
            const SizedBox(height: 14),
          _AttendanceStatusCard(
            loading: _loading,
            errorMessage: _errorMessage,
            summary: _summary,
            onRetry: _loadAttendance,
            onOpen: _openAttendance,
          ),
        ],
      ),
      homeActions: actions,
      details: [
        DashboardDetail(
          label: 'Parent',
          value: profile?.fullName?.trim().isNotEmpty == true
              ? profile!.fullName!
              : _session.welcomeName,
        ),
        if (child != null) ...[
          DashboardDetail(label: 'Student', value: child.title),
          if (child.classLabel.isNotEmpty)
            DashboardDetail(label: 'Class', value: child.classLabel),
          if ((child.rollNumber ?? '').trim().isNotEmpty)
            DashboardDetail(label: 'Roll no.', value: child.rollNumber!.trim()),
          if ((child.branchName ?? '').trim().isNotEmpty)
            DashboardDetail(label: 'Branch', value: child.branchName!.trim()),
        ] else
          const DashboardDetail(
            label: 'Student',
            value: AppStrings.noChildren,
          ),
        DashboardDetail(
          label: 'CNIC',
          value: profile?.cnic?.trim().isNotEmpty == true
              ? profile!.cnic!
              : (_session.user.username ?? '—'),
        ),
        DashboardDetail(
          label: 'Phone',
          value: profile?.phone?.trim().isNotEmpty == true ? profile!.phone! : '—',
        ),
        DashboardDetail(
          label: 'School',
          value: _session.schoolName,
        ),
      ],
      actions: actions,
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
  final ParentAttendanceSummary summary;
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
                    ? Column(
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
                            errorMessage!,
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
                      )
                    : _StatusBody(summary: summary),
          ),
        ),
      ),
    );
  }
}

class _StatusBody extends StatelessWidget {
  const _StatusBody({required this.summary});

  final ParentAttendanceSummary summary;

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
