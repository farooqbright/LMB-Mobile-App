import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../models/school_announcement.dart';

class AnnouncementsBanner extends StatelessWidget {
  const AnnouncementsBanner({
    super.key,
    required this.loading,
    required this.errorMessage,
    required this.announcements,
    required this.onRetry,
  });

  final bool loading;
  final String? errorMessage;
  final List<SchoolAnnouncement> announcements;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (!loading && errorMessage == null && announcements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF99F6E4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF14B8A6)],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppStrings.announcements,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.announcementsHint,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!loading && errorMessage == null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      '${announcements.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            color: const Color(0xFFF0FDFA),
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF0F766E)),
                    ),
                  )
                : errorMessage != null
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(6, 4, 6, 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              errorMessage!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            TextButton(
                              onPressed: onRetry,
                              child: const Text(AppStrings.retry),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          for (var i = 0; i < announcements.length; i++) ...[
                            if (i > 0) const SizedBox(height: 8),
                            _AnnouncementCard(item: announcements[i]),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.item});

  final SchoolAnnouncement item;

  @override
  Widget build(BuildContext context) {
    final meta = <String>[
      if ((item.branchName ?? '').trim().isNotEmpty) item.branchName!.trim(),
      if ((item.publishedLabel ?? '').trim().isNotEmpty) item.publishedLabel!.trim(),
      if ((item.author ?? '').trim().isNotEmpty) item.author!.trim(),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: item.isToday ? const Color(0xFFFFFBEB) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isToday ? const Color(0xFFFBBF24) : const Color(0xFFCCFBF1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    height: 1.3,
                  ),
                ),
              ),
              if (item.isToday) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    AppStrings.today,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (item.body.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.body,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontWeight: FontWeight.w500,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
          ],
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              meta.join(' · '),
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
