import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/media_url.dart';
import '../../models/auth_session.dart';
import '../../services/session_store.dart';
import '../widgets/school_logo.dart';

class ParentStudentSelectView extends StatelessWidget {
  const ParentStudentSelectView({super.key, required this.session});

  final AuthSession session;

  Future<void> _select(BuildContext context, ParentChild child) async {
    final updated = session.withStudent(child);
    await SessionStore.instance.update(updated);
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.parentDashboard,
      (_) => false,
      arguments: updated,
    );
  }

  Future<void> _logout(BuildContext context) async {
    await SessionStore.instance.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final children = session.parentChildren;

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
                    onPressed: () => _logout(context),
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
                  name: session.schoolName,
                  logoUrl: session.schoolLogoUrl,
                  size: 56,
                ),
                const SizedBox(height: 12),
                Text(
                  session.schoolName,
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
            child: children.isEmpty
                ? ListView(
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
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                    itemCount: children.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final child = children[index];
                      return _StudentCard(
                        child: child,
                        photoUrl: MediaUrl.resolve(
                          child.photoUrl,
                          schoolDomain: session.school?.domain,
                        ),
                        selected: session.selectedStudentId == child.studentId,
                        onTap: () => _select(context, child),
                      );
                    },
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
    return Material(
      color: Colors.white,
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
              color: selected ? AppColors.navy : AppColors.border,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Row(
              children: [
                _StudentPhoto(name: child.initials, photoUrl: photoUrl, size: 64),
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
                          color: selected ? AppColors.navy : AppColors.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          height: 1.25,
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
                  color: selected ? AppColors.navy : AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentPhoto extends StatelessWidget {
  const _StudentPhoto({
    required this.name,
    required this.size,
    this.photoUrl,
  });

  final String name;
  final double size;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: photoUrl == null
            ? ColoredBox(
                color: AppColors.primary,
                child: Center(
                  child: Text(
                    name,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: size * 0.32,
                    ),
                  ),
                ),
              )
            : Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: AppColors.primary,
                  child: Center(
                    child: Text(
                      name,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: size * 0.32,
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
