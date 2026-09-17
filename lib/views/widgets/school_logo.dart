import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class SchoolLogo extends StatelessWidget {
  const SchoolLogo({
    super.key,
    required this.name,
    this.logoUrl,
    this.size = 36,
    this.lightBackground = false,
  });

  final String name;
  final String? logoUrl;
  final double size;
  final bool lightBackground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.2),
        border: Border.all(
          color: lightBackground ? AppColors.border : Colors.white.withValues(alpha: 0.7),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl == null
          ? _Fallback(name: name, size: size)
          : Image.network(
              logoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _Fallback(name: name, size: size),
            ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty ? 'S' : name.trim()[0].toUpperCase();
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.42,
          ),
        ),
      ),
    );
  }
}
