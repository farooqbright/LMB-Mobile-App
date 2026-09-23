import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/media_url.dart';
import '../../core/network/api_exception.dart';
import '../../models/auth_session.dart';
import '../../services/auth_service.dart';
import '../../services/session_store.dart';
import '../../views/widgets/pull_to_refresh.dart';
import '../../views/widgets/school_logo.dart';
import '../widgets/parent_student_photo.dart';

class ParentStudentSelectView extends StatefulWidget {
  const ParentStudentSelectView({
    super.key,
    required this.session,
    this.authService,
  });

  final AuthSession session;
  final AuthService? authService;

  @visibleForTesting
  static AuthService? debugAuthService;

  @override
  State<ParentStudentSelectView> createState() => _ParentStudentSelectViewState();
}

class _ParentStudentSelectViewState extends State<ParentStudentSelectView> {
  late AuthSession _session;

  AuthService get _auth =>
      widget.authService ??
      ParentStudentSelectView.debugAuthService ??
      AuthService();

  @override
  void initState() {
    super.initState();
    _session = widget.session;
  }

  Future<void> _select(ParentChild child) async {
    final updated = _session.withStudent(child);
    await SessionStore.instance.update(updated);
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.parentDashboard,
      (_) => false,
      arguments: updated,
    );
  }

  Future<void> _logout() async {
    await SessionStore.instance.clear();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  Future<void> _refresh() async {
    try {
      final updated = await _auth.refreshSession(_session);
      await SessionStore.instance.update(updated);
      if (!mounted) return;
      setState(() => _session = updated);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to refresh students. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = _session.parentChildren;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.paddingOf(context).top + 16,
              12,
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
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _logout,
                    child: const Text(
                      AppStrings.signOut,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SchoolLogo(
                  name: _session.schoolName,
                  logoUrl: _session.schoolLogoUrl,
                  size: 56,
                ),
                const SizedBox(height: 12),
                Text(
                  _session.schoolName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  AppStrings.selectChild,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PullToRefresh(
              onRefresh: _refresh,
              child: children.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
                      children: const [
                        Icon(Icons.family_restroom_rounded, size: 48, color: AppColors.muted),
                        SizedBox(height: 16),
                        Text(
                          AppStrings.noChildren,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          AppStrings.noChildrenHint,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted, height: 1.4),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                      itemCount: children.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final child = children[index];
                        return _StudentCard(
                          child: child,
                          photoUrl: MediaUrl.resolve(
                            child.photoUrl,
                            schoolDomain: _session.school?.domain,
                          ),
                          selected: _session.selectedStudentId == child.studentId,
                          onTap: () => _select(child),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.child,
    required this.photoUrl,
    required this.selected,
    required this.onTap,
  });

  final ParentChild child;
  final String? photoUrl;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final inactive = !child.isActive;

    return Material(
      color: inactive ? AppColors.warningSoft : Colors.white,
      elevation: selected ? 4 : 2,
      shadowColor: AppColors.navy.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: inactive
                  ? const Color(0xFFFECACA)
                  : (selected ? AppColors.navy : AppColors.border),
              width: selected && !inactive ? 1.8 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Row(
              children: [
                ParentStudentPhoto(name: child.initials, photoUrl: photoUrl, size: 64),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected && !inactive ? AppColors.navy : AppColors.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        child.enrollmentCaption,
                        style: TextStyle(
                          color: inactive ? AppColors.warning : AppColors.success,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      if (child.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          child.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      if ((child.relation ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          child.relation!.trim(),
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: selected && !inactive ? AppColors.navy : AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
