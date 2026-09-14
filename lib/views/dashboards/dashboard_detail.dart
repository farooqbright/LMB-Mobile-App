import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class DashboardDetail {
  const DashboardDetail({required this.label, required this.value});

  final String label;
  final String value;
}

class DashboardDetailRow extends StatelessWidget {
  const DashboardDetailRow({super.key, required this.detail});

  final DashboardDetail detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            detail.label,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            detail.value,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
