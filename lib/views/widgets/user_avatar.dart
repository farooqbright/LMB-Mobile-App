import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/auth_session.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.session,
    this.size = 40,
    this.borderWidth = 2,
  });

  final AuthSession session;
  final double size;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final photoUrl = session.photoUrl;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: borderWidth),
      ),
      clipBehavior: Clip.antiAlias,
      child: photoUrl == null
          ? _Initials(session: session, size: size)
          : Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _Initials(session: session, size: size),
            ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.session, required this.size});

  final AuthSession session;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.primary,
      child: Center(
        child: Text(
          session.initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.36,
          ),
        ),
      ),
    );
  }
}
