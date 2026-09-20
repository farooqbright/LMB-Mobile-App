import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class ParentLoadMore extends StatelessWidget {
  const ParentLoadMore({
    super.key,
    required this.loading,
    required this.onPressed,
  });

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(color: AppColors.navy, strokeWidth: 2.4),
          ),
        ),
      );
    }

    return Center(
      child: TextButton(
        onPressed: onPressed,
        child: const Text(AppStrings.loadMore),
      ),
    );
  }
}
