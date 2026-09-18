import '../core/media_url.dart';

enum UserAudience { parent, teacher }

class School {
  const School({
    this.id,
    this.name,
    this.domain,
    this.logoUrl,
  });

  final String? id;
  final String? name;
  final String? domain;
  final String? logoUrl;

  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      id: json['id']?.toString(),
      name: json['name'] as String?,
      domain: json['domain'] as String?,
      logoUrl: json['logo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'domain': domain,
        'logo_url': logoUrl,
      };
}

class AuthUser {
  const AuthUser({
    required this.id,
    this.name,
    this.lastName,
    this.email,
    this.username,
    this.roles = const [],
    this.avatarUrl,
  });

  final int id;
  final String? name;
  final String? lastName;
  final String? email;
  final String? username;
  final List<String> roles;
  final String? avatarUrl;

  String get displayName {
    final parts = [name, lastName].where((part) => part != null && part.trim().isNotEmpty);
    if (parts.isEmpty) return username ?? email ?? 'User';
    return parts.join(' ');
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: _asInt(json['id']) ?? 0,
      name: json['name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
      username: json['username'] as String?,
      roles: (json['roles'] as List?)?.map((role) => role.toString()).toList() ?? const [],
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'last_name': lastName,
        'email': email,
        'username': username,
        'roles': roles,
        'avatar_url': avatarUrl,
      };
}

class ParentProfile {
  const ParentProfile({
    this.guardianId,
    this.fullName,
    this.cnic,
    this.phone,
  });

  final int? guardianId;
  final String? fullName;
  final String? cnic;
  final String? phone;

  factory ParentProfile.fromJson(Map<String, dynamic> json) {
    return ParentProfile(
      guardianId: _asInt(json['guardian_id']),
      fullName: json['full_name'] as String?,
      cnic: json['cnic'] as String?,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': 'parent',
        'guardian_id': guardianId,
        'full_name': fullName,
        'cnic': cnic,
        'phone': phone,
      };
}

class TeacherBranch {
  const TeacherBranch({
    required this.branchId,
    this.branchName,
    this.logoUrl,
  });

  final int branchId;
  final String? branchName;
  final String? logoUrl;

  String get title {
    final value = branchName?.trim();
    if (value != null && value.isNotEmpty) return value;
    return 'Branch $branchId';
  }

  factory TeacherBranch.fromJson(Map<String, dynamic> json) {
    return TeacherBranch(
      branchId: _asInt(json['branch_id']) ?? 0,
      branchName: json['branch_name'] as String?,
      logoUrl: json['logo_url'] as String? ?? json['branch_logo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'branch_id': branchId,
        'branch_name': branchName,
        'logo_url': logoUrl,
      };
}

class TeacherProfile {
  const TeacherProfile({
    this.teacherId,
    this.branchId,
    this.branchName,
    this.branchLogoUrl,
    this.branches = const [],
    this.fullName,
    this.fatherName,
    this.employeeNumber,
    this.cnic,
    this.phone,
    this.email,
    this.gender,
    this.dateOfBirth,
    this.religion,
    this.city,
    this.residentialAddress,
    this.joiningDate,
    this.photoUrl,
  });

  final int? teacherId;
  final int? branchId;
  final String? branchName;
  final String? branchLogoUrl;
  final List<TeacherBranch> branches;
  final String? fullName;
  final String? fatherName;
  final String? employeeNumber;
  final String? cnic;
  final String? phone;
  final String? email;
  final String? gender;
  final String? dateOfBirth;
  final String? religion;
  final String? city;
  final String? residentialAddress;
  final String? joiningDate;
  final String? photoUrl;

  factory TeacherProfile.fromJson(Map<String, dynamic> json) {
    return TeacherProfile(
      teacherId: _asInt(json['teacher_id']),
      branchId: _asInt(json['branch_id']),
      branchName: json['branch_name'] as String?,
      branchLogoUrl: json['branch_logo_url'] as String?,
      branches: _parseTeacherBranches(json),
      fullName: json['full_name'] as String?,
      fatherName: json['father_name'] as String?,
      employeeNumber: json['employee_number'] as String?,
      cnic: json['cnic'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      gender: json['gender'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      religion: json['religion'] as String?,
      city: json['city'] as String?,
      residentialAddress: json['residential_address'] as String?,
      joiningDate: json['joining_date'] as String?,
      photoUrl: json['photo_url'] as String?,
    );
  }

  TeacherProfile copyWith({
    int? branchId,
    String? branchName,
    String? branchLogoUrl,
  }) {
    return TeacherProfile(
      teacherId: teacherId,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      branchLogoUrl: branchLogoUrl ?? this.branchLogoUrl,
      branches: branches,
      fullName: fullName,
      fatherName: fatherName,
      employeeNumber: employeeNumber,
      cnic: cnic,
      phone: phone,
      email: email,
      gender: gender,
      dateOfBirth: dateOfBirth,
      religion: religion,
      city: city,
      residentialAddress: residentialAddress,
      joiningDate: joiningDate,
      photoUrl: photoUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': 'teacher',
        'teacher_id': teacherId,
        'branch_id': branchId,
        'branch_name': branchName,
        'branch_logo_url': branchLogoUrl,
        'branches': branches.map((branch) => branch.toJson()).toList(),
        'full_name': fullName,
        'father_name': fatherName,
        'employee_number': employeeNumber,
        'cnic': cnic,
        'phone': phone,
        'email': email,
        'gender': gender,
        'date_of_birth': dateOfBirth,
        'religion': religion,
        'city': city,
        'residential_address': residentialAddress,
        'joining_date': joiningDate,
        'photo_url': photoUrl,
      };
}

class AuthSession {
  const AuthSession({
    required this.token,
    required this.tokenType,
    required this.audience,
    required this.user,
    this.school,
    this.parentProfile,
    this.teacherProfile,
    this.selectedBranchId,
  });

  final String token;
  final String tokenType;
  final UserAudience audience;
  final AuthUser user;
  final School? school;
  final ParentProfile? parentProfile;
  final TeacherProfile? teacherProfile;
  final int? selectedBranchId;

  bool get isTeacher => audience == UserAudience.teacher;
  bool get isParent => audience == UserAudience.parent;

  List<TeacherBranch> get teacherBranches => teacherProfile?.branches ?? const [];

  /// Campus used for teacher APIs after login or branch selection.
  int? get activeBranchId =>
      selectedBranchId ?? teacherProfile?.branchId;

  bool get needsBranchSelection =>
      isTeacher && teacherBranches.length > 1 && selectedBranchId == null;

  TeacherBranch? get selectedBranch {
    final id = selectedBranchId;
    if (id == null) return null;
    for (final branch in teacherBranches) {
      if (branch.branchId == id) return branch;
    }
    return null;
  }

  String? get selectedBranchName {
    final name = selectedBranch?.title ?? teacherProfile?.branchName?.trim();
    if (name == null || name.isEmpty) return null;
    return name;
  }

  String? get selectedBranchLogoUrl {
    final logo = selectedBranch?.logoUrl?.trim() ?? teacherProfile?.branchLogoUrl?.trim();
    if (logo == null || logo.isEmpty) return null;
    return logo;
  }

  String get welcomeName {
    if (isTeacher && (teacherProfile?.fullName ?? '').trim().isNotEmpty) {
      return teacherProfile!.fullName!.trim();
    }
    if (isParent && (parentProfile?.fullName ?? '').trim().isNotEmpty) {
      return parentProfile!.fullName!.trim();
    }
    return user.displayName;
  }

  String get schoolName => school?.name?.trim().isNotEmpty == true
      ? school!.name!.trim()
      : 'School LMS';

  String? get schoolLogoUrl {
    final logo = school?.logoUrl?.trim();
    if (logo == null || logo.isEmpty) return null;
    return logo;
  }

  String? get photoUrl {
    final teacherPhoto = teacherProfile?.photoUrl?.trim();
    if (teacherPhoto != null && teacherPhoto.isNotEmpty) {
      return MediaUrl.resolve(teacherPhoto, schoolDomain: school?.domain);
    }
    return MediaUrl.resolve(user.avatarUrl, schoolDomain: school?.domain);
  }

  String get initials {
    final parts = welcomeName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'T';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final type = json['type'] == 'teacher' ? UserAudience.teacher : UserAudience.parent;
    final profile = json['profile'];
    final school = json['school'];
    final user = json['user'];

    if (user is! Map<String, dynamic>) {
      throw const FormatException('Login response is missing user data.');
    }

    final teacherProfile = type == UserAudience.teacher && profile is Map<String, dynamic>
        ? TeacherProfile.fromJson(profile)
        : null;
    var selectedBranchId = _asInt(json['selected_branch_id']);
    if (type == UserAudience.teacher &&
        selectedBranchId == null &&
        teacherProfile != null &&
        teacherProfile.branches.length == 1) {
      selectedBranchId = teacherProfile.branches.first.branchId;
    }

    return AuthSession(
      token: json['token'] as String? ?? '',
      tokenType: json['token_type'] as String? ?? 'Bearer',
      audience: type,
      school: school is Map<String, dynamic> ? School.fromJson(school) : null,
      user: AuthUser.fromJson(user),
      parentProfile: type == UserAudience.parent && profile is Map<String, dynamic>
          ? ParentProfile.fromJson(profile)
          : null,
      teacherProfile: teacherProfile,
      selectedBranchId: selectedBranchId,
    );
  }

  AuthSession withBranch(TeacherBranch branch) {
    return AuthSession(
      token: token,
      tokenType: tokenType,
      audience: audience,
      user: user,
      school: school,
      parentProfile: parentProfile,
      teacherProfile: teacherProfile?.copyWith(
        branchId: branch.branchId,
        branchName: branch.branchName,
        branchLogoUrl: branch.logoUrl,
      ),
      selectedBranchId: branch.branchId,
    );
  }

  Map<String, dynamic> toJson() => {
        'token': token,
        'token_type': tokenType,
        'type': isTeacher ? 'teacher' : 'parent',
        'school': school?.toJson(),
        'user': user.toJson(),
        'profile': isTeacher ? teacherProfile?.toJson() : parentProfile?.toJson(),
        'selected_branch_id': selectedBranchId,
      };
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

List<TeacherBranch> _parseTeacherBranches(Map<String, dynamic> json) {
  final raw = json['branches'];
  if (raw is List) {
    final branches = [
      for (final item in raw)
        if (item is Map) TeacherBranch.fromJson(Map<String, dynamic>.from(item)),
    ].where((branch) => branch.branchId > 0).toList();
    if (branches.isNotEmpty) return branches;
  }

  final branchId = _asInt(json['branch_id']);
  if (branchId == null) return const [];
  return [
    TeacherBranch(
      branchId: branchId,
      branchName: json['branch_name'] as String?,
      logoUrl: json['branch_logo_url'] as String?,
    ),
  ];
}
