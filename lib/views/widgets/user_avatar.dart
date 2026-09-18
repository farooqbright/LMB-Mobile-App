import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/auth_session.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.session,
    this.size = 40,
  });

  final AuthSession session;
  final double size;

  @override
  Widget build(BuildContext context) {
    final photoUrl = session.photoUrl;

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: photoUrl == null
            ? _Initials(session: session, size: size)
            : Image.network(
                photoUrl,
                fit: BoxFit.cover,
                width: size,
                height: size,
                alignment: Alignment.center,
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => _Initials(session: session, size: size),
              ),
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
