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

class ParentChild {
  const ParentChild({
    required this.studentId,
    this.fullName,
    this.rollNumber,
    this.photoUrl,
    this.branchId,
    this.branchName,
    this.className,
    this.sectionName,
    this.sessionName,
    this.relation,
    this.isActive = true,
    this.enrollmentStatus,
    this.statusLabel,
  });

  final int studentId;
  final String? fullName;
  final String? rollNumber;
  final String? photoUrl;
  final int? branchId;
  final String? branchName;
  final String? className;
  final String? sectionName;
  final String? sessionName;
  final String? relation;
  final bool isActive;
  final String? enrollmentStatus;
  final String? statusLabel;

  String get enrollmentCaption {
    final label = (statusLabel ?? '').trim();
    if (label.isEmpty) {
      return isActive ? 'Active Student' : 'Inactive Student';
    }
    final lower = label.toLowerCase();
    if (lower.endsWith('student')) return label;
    return '$label Student';
  }

  String get title {
    final value = fullName?.trim();
    if (value != null && value.isNotEmpty) return value;
    return 'Student $studentId';
  }

  String get classLabel {
    final klass = className?.trim();
    final section = sectionName?.trim();
    if (klass != null && klass.isNotEmpty && section != null && section.isNotEmpty) {
      return '$klass - $section';
    }
    if (klass != null && klass.isNotEmpty) return klass;
    if (section != null && section.isNotEmpty) return section;
    return '';
  }

  String get subtitle {
    final parts = [
      classLabel,
      if ((rollNumber ?? '').trim().isNotEmpty) 'Roll ${rollNumber!.trim()}',
      if ((branchName ?? '').trim().isNotEmpty) branchName!.trim(),
    ].where((part) => part.isNotEmpty).toList();
    return parts.join(' · ');
  }

  String get initials {
    final parts = title
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'S';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  factory ParentChild.fromJson(Map<String, dynamic> json) {
    final enrollmentActive = json['is_enrollment_active'] is bool
        ? json['is_enrollment_active'] as bool
        : json['is_active'] != false;
    final statusLabel = (json['status_label'] as String?)?.trim();

    return ParentChild(
      studentId: _asInt(json['student_id']) ?? _asInt(json['id']) ?? 0,
      fullName: json['full_name'] as String?,
      rollNumber: json['roll_number'] as String?,
      photoUrl: json['photo_url'] as String?,
      branchId: _asInt(json['branch_id']),
      branchName: json['branch_name'] as String?,
      className: json['class_name'] as String?,
      sectionName: json['section_name'] as String?,
      sessionName: json['session_name'] as String?,
      relation: json['relation'] as String?,
      isActive: enrollmentActive,
      enrollmentStatus: json['enrollment_status'] as String?,
      statusLabel: (statusLabel != null && statusLabel.isNotEmpty)
          ? statusLabel
          : (enrollmentActive ? 'Active' : 'Inactive'),
    );
  }

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'full_name': fullName,
        'roll_number': rollNumber,
        'photo_url': photoUrl,
        'branch_id': branchId,
        'branch_name': branchName,
        'class_name': className,
        'section_name': sectionName,
        'session_name': sessionName,
        'relation': relation,
        'is_active': isActive,
        'enrollment_status': enrollmentStatus,
        'is_enrollment_active': isActive,
        'status_label': statusLabel,
      };
}

class ParentProfile {
  const ParentProfile({
    this.guardianId,
    this.fullName,
    this.cnic,
    this.phone,
    this.children = const [],
  });

  final int? guardianId;
  final String? fullName;
  final String? cnic;
  final String? phone;
  final List<ParentChild> children;

  factory ParentProfile.fromJson(Map<String, dynamic> json) {
    return ParentProfile(
      guardianId: _asInt(json['guardian_id']),
      fullName: json['full_name'] as String?,
      cnic: json['cnic'] as String?,
      phone: json['phone'] as String?,
      children: _parseParentChildren(json),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': 'parent',
        'guardian_id': guardianId,
        'full_name': fullName,
        'cnic': cnic,
        'phone': phone,
        'children': children.map((child) => child.toJson()).toList(),
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
    this.selectedStudentId,
  });

  final String token;
  final String tokenType;
  final UserAudience audience;
  final AuthUser user;
  final School? school;
  final ParentProfile? parentProfile;
  final TeacherProfile? teacherProfile;
  final int? selectedBranchId;
  final int? selectedStudentId;

  bool get isTeacher => audience == UserAudience.teacher;
  bool get isParent => audience == UserAudience.parent;

  List<TeacherBranch> get teacherBranches => teacherProfile?.branches ?? const [];

  List<ParentChild> get parentChildren => parentProfile?.children ?? const [];

  /// Campus used for teacher APIs after login or branch selection.
  int? get activeBranchId =>
      selectedBranchId ?? teacherProfile?.branchId;

  bool get needsBranchSelection =>
      isTeacher && teacherBranches.length > 1 && selectedBranchId == null;

  bool get needsStudentSelection =>
      isParent && parentChildren.length > 1 && selectedStudentId == null;

  TeacherBranch? get selectedBranch {
    final id = selectedBranchId;
    if (id == null) return null;
    for (final branch in teacherBranches) {
      if (branch.branchId == id) return branch;
    }
    return null;
  }

  ParentChild? get selectedStudent {
    final id = selectedStudentId;
    if (id == null) return null;
    for (final child in parentChildren) {
      if (child.studentId == id) return child;
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

  String? get selectedStudentName {
    final name = selectedStudent?.title.trim();
    if (name == null || name.isEmpty) return null;
    return name;
  }

  String? get selectedStudentPhotoUrl {
    return MediaUrl.resolve(
      selectedStudent?.photoUrl,
      schoolDomain: school?.domain,
    );
  }

  String get workspaceTitle {
    if (isParent) return selectedStudentName ?? schoolName;
    return selectedBranchName ?? schoolName;
  }

  String? get workspaceLogoUrl {
    if (isParent) return schoolLogoUrl;
    return selectedBranchLogoUrl ?? schoolLogoUrl;
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
    final parentProfile = type == UserAudience.parent && profile is Map<String, dynamic>
        ? ParentProfile.fromJson(profile)
        : null;
    var selectedBranchId = _asInt(json['selected_branch_id']);
    if (type == UserAudience.teacher &&
        selectedBranchId == null &&
        teacherProfile != null &&
        teacherProfile.branches.length == 1) {
      selectedBranchId = teacherProfile.branches.first.branchId;
    }

    var selectedStudentId = _asInt(json['selected_student_id']);
    final children = parentProfile?.children ?? const <ParentChild>[];
    if (type == UserAudience.parent) {
      final exists = selectedStudentId != null &&
          children.any((child) => child.studentId == selectedStudentId);
      if (!exists) {
        selectedStudentId = children.length == 1 ? children.first.studentId : null;
      }
    }

    return AuthSession(
      token: json['token'] as String? ?? '',
      tokenType: json['token_type'] as String? ?? 'Bearer',
      audience: type,
      school: school is Map<String, dynamic> ? School.fromJson(school) : null,
      user: AuthUser.fromJson(user),
      parentProfile: parentProfile,
      teacherProfile: teacherProfile,
      selectedBranchId: selectedBranchId,
      selectedStudentId: selectedStudentId,
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
      selectedStudentId: selectedStudentId,
    );
  }

  AuthSession withStudent(ParentChild child) {
    return AuthSession(
      token: token,
      tokenType: tokenType,
      audience: audience,
      user: user,
      school: school,
      parentProfile: parentProfile,
      teacherProfile: teacherProfile,
      selectedBranchId: selectedBranchId,
      selectedStudentId: child.studentId,
    );
  }

  AuthSession mergingProfile(Map<String, dynamic> data) {
    return AuthSession.fromJson({
      ...data,
      'token': token.isNotEmpty ? token : (data['token'] as String? ?? ''),
      'token_type': tokenType.isNotEmpty
          ? tokenType
          : (data['token_type'] as String? ?? 'Bearer'),
      'type': data['type'] ?? (isTeacher ? 'teacher' : 'parent'),
      'selected_branch_id': selectedBranchId,
      'selected_student_id': selectedStudentId,
    });
  }

  Map<String, dynamic> toJson() => {
        'token': token,
        'token_type': tokenType,
        'type': isTeacher ? 'teacher' : 'parent',
        'school': school?.toJson(),
        'user': user.toJson(),
        'profile': isTeacher ? teacherProfile?.toJson() : parentProfile?.toJson(),
        'selected_branch_id': selectedBranchId,
        'selected_student_id': selectedStudentId,
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

List<ParentChild> _parseParentChildren(Map<String, dynamic> json) {
  final raw = json['children'];
  if (raw is! List) return const [];
  return [
    for (final item in raw)
      if (item is Map) ParentChild.fromJson(Map<String, dynamic>.from(item)),
  ].where((child) => child.studentId > 0).toList();
}
