import 'package:flutter_test/flutter_test.dart';
import 'package:lmssystem/app/routes.dart';
import 'package:lmssystem/models/auth_session.dart';

void main() {
  test('parses parent login payload', () {
    final session = AuthSession.fromJson({
      'token': 'abc.token',
      'token_type': 'Bearer',
      'type': 'parent',
      'school': {'id': '1', 'name': 'SLS', 'domain': 'sls.localhost'},
      'user': {
        'id': 9,
        'name': 'Ali',
        'last_name': 'Parent',
        'email': null,
        'username': '34101-0111110-6',
        'roles': ['Parent'],
        'avatar_url': null,
      },
      'profile': {
        'type': 'parent',
        'guardian_id': 4,
        'full_name': 'Ali Parent',
        'cnic': '34101-0111110-6',
        'phone': '0300-1111111',
      },
    });

    expect(session.isParent, isTrue);
    expect(session.welcomeName, 'Ali Parent');
    expect(session.schoolName, 'SLS');
    expect(session.parentProfile?.cnic, '34101-0111110-6');
  });

  test('parses teacher login payload', () {
    final session = AuthSession.fromJson({
      'token': 'teacher.token',
      'token_type': 'Bearer',
      'type': 'teacher',
      'school': {
        'id': '1',
        'name': 'SLS',
        'domain': 'sls.localhost',
        'logo_url': 'http://localhost:8000/storage/logo.png',
      },
      'user': {
        'id': 3,
        'name': 'Sara',
        'last_name': 'Khan',
        'email': 'teacher@example.com',
        'username': 'teacher@example.com',
        'roles': ['Teacher'],
        'avatar_url': null,
      },
      'profile': {
        'type': 'teacher',
        'teacher_id': 2,
        'branch_id': 1,
        'full_name': 'Sara Khan',
        'employee_number': 'T-01',
        'father_name': 'Ahmed Khan',
        'phone': '0300-2222222',
        'photo_url': 'http://localhost:8000/storage/teachers/sara.png',
        'branch_name': 'Main Campus',
        'cnic': '35201-1234567-1',
      },
    });

    expect(session.isTeacher, isTrue);
    expect(session.welcomeName, 'Sara Khan');
    expect(session.schoolLogoUrl, 'http://localhost:8000/storage/logo.png');
    expect(session.teacherProfile?.employeeNumber, 'T-01');
    expect(session.teacherProfile?.fatherName, 'Ahmed Khan');
    expect(session.photoUrl, 'http://sls.localhost/tenancy/assets/teachers/sara.png');
    expect(session.initials, 'SK');
    expect(session.needsBranchSelection, isFalse);
    expect(session.selectedBranchId, 1);
    expect(session.activeBranchId, 1);
    expect(session.teacherBranches, hasLength(1));
  });

  test('builds drawer photo from stored path and login domain', () {
    final session = AuthSession.fromJson({
      'token': 'teacher.token',
      'token_type': 'Bearer',
      'type': 'teacher',
      'school': {'id': '1', 'name': 'SLS', 'domain': 'sls.localhost'},
      'user': {
        'id': 3,
        'name': 'Sara',
        'last_name': 'Khan',
        'username': 'teacher@example.com',
        'roles': ['Teacher'],
      },
      'profile': {
        'type': 'teacher',
        'teacher_id': 2,
        'branch_id': 1,
        'full_name': 'Sara Khan',
        'photo_url': 'teachers/542532c4-90db-44bf-9770-85a7085497e2.jpg',
      },
    });

    expect(
      session.photoUrl,
      'http://sls.localhost/tenancy/assets/teachers/542532c4-90db-44bf-9770-85a7085497e2.jpg',
    );
  });

  test('teacher with multiple branches must pick one', () {
    final session = AuthSession.fromJson({
      'token': 'teacher.token',
      'token_type': 'Bearer',
      'type': 'teacher',
      'school': {'id': '1', 'name': 'SLS', 'domain': 'sls.localhost'},
      'user': {
        'id': 3,
        'name': 'Sara',
        'last_name': 'Khan',
        'email': 'teacher@example.com',
        'username': 'teacher@example.com',
        'roles': ['Teacher'],
      },
      'profile': {
        'type': 'teacher',
        'teacher_id': 2,
        'branch_id': 1,
        'branch_name': 'Avicenna Campus',
        'full_name': 'Sara Khan',
        'branches': [
          {
            'branch_id': 1,
            'branch_name': 'Avicenna Campus',
            'logo_url': 'http://localhost:8000/storage/avicenna.png',
          },
          {
            'branch_id': 2,
            'branch_name': 'Ibn Sina Campus',
            'logo_url': 'http://localhost:8000/storage/ibn.png',
          },
        ],
      },
    });

    expect(session.needsBranchSelection, isTrue);
    expect(session.teacherBranches, hasLength(2));
    expect(AppRoutes.dashboardFor(session), AppRoutes.teacherBranchSelect);

    final chosen = session.withBranch(session.teacherBranches.last);
    expect(chosen.needsBranchSelection, isFalse);
    expect(chosen.selectedBranchId, 2);
    expect(chosen.activeBranchId, 2);
    expect(chosen.selectedBranchName, 'Ibn Sina Campus');
    expect(AppRoutes.dashboardFor(chosen), AppRoutes.teacherDashboard);
  });
}
