import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/auth_session.dart';
import '../../services/session_store.dart';
import '../../parent/widgets/parent_student_photo.dart';
import '../profile/teacher_profile_view.dart';
import '../widgets/pull_to_refresh.dart';
import '../widgets/school_logo.dart';
import '../widgets/user_avatar.dart';
import 'dashboard_detail.dart';
import 'quick_access_card.dart';

export 'dashboard_detail.dart';
export 'quick_access_card.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({
    super.key,
    required this.session,
    required this.actions,
    this.homeActions = const [],
    this.details = const [],
    this.homeContent,
    this.onRefresh,
  });

  final AuthSession session;
  final List<DashboardDetail> details;
  final List<DashboardAction> actions;
  final List<DashboardAction> homeActions;
  final Widget? homeContent;
  final Future<void> Function()? onRefresh;

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  static const _homeTab = 0;
  static const _profileTab = 1;
  static const _logoutTab = 2;

  final _navKey = GlobalKey<CurvedNavigationBarState>();
  int _tab = _homeTab;

  Future<void> _logout() async {
    await SessionStore.instance.clear();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  void _onNavTap(int index) {
    if (index == _logoutTab) {
      _navKey.currentState?.setPage(_tab);
      _logout();
      return;
    }
    if (index == _homeTab || index == _profileTab) {
      setState(() => _tab = index);
    }
  }

  void _comingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.navy,
        content: Text('$label will be available in the next update.'),
      ),
    );
  }

  void _onActionTap(DashboardAction action) {
    if (action.route != null) {
      Navigator.of(context).pushNamed(action.route!, arguments: widget.session);
      return;
    }
    _comingSoon(action.label);
  }

  bool get _canSwitchSelection {
    if (widget.session.isTeacher) {
      return widget.session.teacherBranches.length > 1;
    }
    return widget.session.isParent && widget.session.parentChildren.length > 1;
  }

  void _goToSelection() {
    Navigator.of(context).pushReplacementNamed(
      widget.session.isParent
          ? AppRoutes.parentStudentSelect
          : AppRoutes.teacherBranchSelect,
      arguments: widget.session,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_canSwitchSelection,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !_canSwitchSelection) return;
        _goToSelection();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        extendBody: true,
        drawer: _DashboardDrawer(
          session: widget.session,
          actions: widget.actions,
          onActionTap: _onActionTap,
        ),
        body: IndexedStack(
          index: _tab,
          children: [
            _HomeTab(
              session: widget.session,
              details: widget.details,
              homeContent: widget.homeContent,
              homeActions: widget.homeActions,
              onActionTap: _onActionTap,
              onRefresh: widget.onRefresh,
              onBackToSelection: _canSwitchSelection ? _goToSelection : null,
            ),
            widget.session.isTeacher
                ? TeacherProfileContent(session: widget.session)
                : _ParentProfileTab(
                    session: widget.session,
                    details: widget.details,
                  ),
          ],
        ),
        bottomNavigationBar: CurvedNavigationBar(
          key: _navKey,
          index: _tab,
          height: 60,
          color: AppColors.navy,
          buttonBackgroundColor: AppColors.navyDeep,
          backgroundColor: AppColors.background,
          animationDuration: const Duration(milliseconds: 280),
          items: const [
            Icon(Icons.home_rounded, color: Colors.white, size: 26),
            Icon(Icons.person_rounded, color: Colors.white, size: 26),
            Icon(Icons.logout_rounded, color: Colors.white, size: 26),
          ],
          onTap: _onNavTap,
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.session,
    required this.details,
    this.homeContent,
    this.homeActions = const [],
    this.onActionTap,
    this.onRefresh,
    this.onBackToSelection,
  });

  final AuthSession session;
  final List<DashboardDetail> details;
  final Widget? homeContent;
  final List<DashboardAction> homeActions;
  final ValueChanged<DashboardAction>? onActionTap;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onBackToSelection;

  @override
  Widget build(BuildContext context) {
    return PullToRefresh(
      displacement: 56,
      edgeOffset: MediaQuery.paddingOf(context).top + 8,
      notificationPredicate: (_) => onRefresh != null,
      onRefresh: onRefresh ?? () async {},
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (homeContent != null) ...[
                  homeContent!,
                  const SizedBox(height: 18),
                ],
                if (homeActions.isNotEmpty) ...[
                  GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      mainAxisExtent: 72,
                    ),
                    children: [
                      for (final action in homeActions)
                        QuickAccessCard(
                          action: action,
                          onTap: () => onActionTap?.call(action),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                ],
                if (details.isNotEmpty && !session.isTeacher && homeContent == null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < details.length; i++) ...[
                          if (i > 0) const Divider(height: 22),
                          DashboardDetailRow(detail: details[i]),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        8,
        MediaQuery.paddingOf(context).top + 8,
        8,
        12,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, AppColors.navyDeep],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: AppStrings.menu,
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SchoolLogo(
                  name: session.workspaceTitle,
                  logoUrl: session.workspaceLogoUrl,
                  size: 40,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    session.workspaceTitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (onBackToSelection != null)
            IconButton(
              onPressed: onBackToSelection,
              tooltip: session.isParent
                  ? AppStrings.selectChild
                  : AppStrings.selectBranch,
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _DashboardDrawer extends StatelessWidget {
  const _DashboardDrawer({
    required this.session,
    required this.actions,
    required this.onActionTap,
  });

  final AuthSession session;
  final List<DashboardAction> actions;
  final ValueChanged<DashboardAction> onActionTap;

  @override
  Widget build(BuildContext context) {
    final child = session.isParent ? session.selectedStudent : null;
    final title = child?.title ?? session.welcomeName;
    final subtitle = child != null
        ? child.classLabel
        : (session.isTeacher ? AppStrings.teacherRole : AppStrings.parentRole);

    return Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.paddingOf(context).top + 28,
              20,
              24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.navy, AppColors.navyDeep],
              ),
            ),
            child: Column(
              children: [
                if (child != null)
                  ParentStudentPhoto(
                    name: child.initials,
                    photoUrl: session.selectedStudentPhotoUrl,
                    size: 128,
                  )
                else
                  UserAvatar(session: session, size: 128),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (final action in actions)
                  ListTile(
                    leading: Icon(action.icon, color: AppColors.navy),
                    title: Text(
                      action.label,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      onActionTap(action);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentProfileTab extends StatelessWidget {
  const _ParentProfileTab({
    required this.session,
    required this.details,
  });

  final AuthSession session;
  final List<DashboardDetail> details;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 16,
        20,
        96,
      ),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              UserAvatar(session: session, size: 112),
              const SizedBox(height: 16),
              Text(
                session.welcomeName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                AppStrings.parentRole,
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (details.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < details.length; i++) ...[
                  if (i > 0) const Divider(height: 22),
                  DashboardDetailRow(detail: details[i]),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
