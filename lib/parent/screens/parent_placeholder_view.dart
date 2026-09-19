import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class ParentPlaceholderView extends StatelessWidget {
  const ParentPlaceholderView({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: const Padding(
        padding: EdgeInsets.fromLTRB(24, 48, 24, 32),
        child: Column(
          children: [
            Icon(Icons.hourglass_empty_rounded, size: 48, color: AppColors.muted),
            SizedBox(height: 16),
            Text(
              AppStrings.comingSoon,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              AppStrings.comingSoonHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
