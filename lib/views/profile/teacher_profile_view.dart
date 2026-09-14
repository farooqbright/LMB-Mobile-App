import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/auth_session.dart';
import '../dashboards/dashboard_detail.dart';
import '../widgets/user_avatar.dart';

class TeacherProfileView extends StatelessWidget {
  const TeacherProfileView({super.key, required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.profile),
      ),
      body: TeacherProfileContent(session: session),
    );
  }
}

class TeacherProfileContent extends StatelessWidget {
  const TeacherProfileContent({super.key, required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    final profile = session.teacherProfile;
    final details = [
      DashboardDetail(label: 'Full name', value: _text(profile?.fullName, session.welcomeName)),
      DashboardDetail(label: 'Father name', value: _text(profile?.fatherName)),
      DashboardDetail(label: 'Employee no.', value: _text(profile?.employeeNumber)),
      DashboardDetail(label: 'CNIC', value: _text(profile?.cnic)),
      DashboardDetail(label: 'Gender', value: _titleCase(profile?.gender)),
      DashboardDetail(label: 'Date of birth', value: _date(profile?.dateOfBirth)),
      DashboardDetail(label: 'Religion', value: _text(profile?.religion)),
      DashboardDetail(label: 'Phone', value: _text(profile?.phone)),
      DashboardDetail(
        label: 'Email',
        value: _text(profile?.email, session.user.email),
      ),
      DashboardDetail(label: 'City', value: _text(profile?.city)),
      DashboardDetail(label: 'Address', value: _text(profile?.residentialAddress)),
      DashboardDetail(label: 'Joining date', value: _date(profile?.joiningDate)),
      DashboardDetail(label: 'Branch', value: _text(profile?.branchName)),
      DashboardDetail(label: 'School', value: session.schoolName),
      DashboardDetail(label: 'Domain', value: _text(session.school?.domain)),
      DashboardDetail(
        label: 'Username',
        value: _text(session.user.username, session.user.email),
      ),
    ];

    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 16,
        20,
        96,
      ),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              UserAvatar(session: session, size: 112, borderWidth: 3),
              const SizedBox(height: 16),
              Text(
                session.welcomeName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                AppStrings.teacherRole,
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < details.length; i++) ...[
                if (i > 0) const Divider(height: 22),
                DashboardDetailRow(detail: details[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static String _text(String? value, [String? fallback]) {
    final primary = value?.trim() ?? '';
    if (primary.isNotEmpty) return primary;
    final secondary = fallback?.trim() ?? '';
    return secondary.isEmpty ? '—' : secondary;
  }

  static String _titleCase(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '—';
    return text[0].toUpperCase() + text.substring(1);
  }

  static String _date(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return '—';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }
}
