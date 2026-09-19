import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class ParentStudentPhoto extends StatelessWidget {
  const ParentStudentPhoto({
    super.key,
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
            ? _Initials(name: name, size: size)
            : Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                width: size,
                height: size,
                alignment: Alignment.center,
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => _Initials(name: name, size: size),
              ),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
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
    );
  }
}
