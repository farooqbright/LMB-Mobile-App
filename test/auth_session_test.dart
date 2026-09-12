import 'package:flutter_test/flutter_test.dart';
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
      'school': {'id': '1', 'name': 'SLS', 'domain': 'sls.localhost'},
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
        'phone': '0300-2222222',
        'photo_url': null,
      },
    });

    expect(session.isTeacher, isTrue);
    expect(session.welcomeName, 'Sara Khan');
    expect(session.teacherProfile?.employeeNumber, 'T-01');
  });
}
