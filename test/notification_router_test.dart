import 'package:flutter_test/flutter_test.dart';
import 'package:lmssystem/app/routes.dart';
import 'package:lmssystem/models/auth_session.dart';
import 'package:lmssystem/services/notification_router.dart';

AuthSession _parentWithChildren() {
  return AuthSession.fromJson({
    'token': 'parent.token',
    'token_type': 'Bearer',
    'type': 'parent',
    'school': {'id': '1', 'name': 'SLS', 'domain': 'sls.localhost'},
    'user': {
      'id': 110,
      'name': 'Tanveer',
      'roles': ['Parent'],
    },
    'profile': {
      'type': 'parent',
      'guardian_id': 293,
      'full_name': 'MIAN MUHAMMAD TANVEER',
      'children': [
        {
          'student_id': 297,
          'full_name': 'AFAF TANVEER',
          'class_name': 'GRADE PRE-9th',
        },
        {
          'student_id': 24,
          'full_name': 'HASHIM BIN TANVEER',
          'class_name': 'Play Group',
        },
      ],
    },
  });
}

void main() {
  test('notification tap selects the student from the payload', () {
    final session = _parentWithChildren();
    final updated = NotificationRouter.applyStudent(session, {
      'kind': 'special_remark',
      'student_id': '297',
    });

    expect(updated?.selectedStudentId, 297);
    expect(updated?.selectedStudentName, 'AFAF TANVEER');
  });

  test('notification tap still selects a student not already in the session', () {
    final session = _parentWithChildren();
    final updated = NotificationRouter.applyStudent(session, {
      'kind': 'special_remark',
      'student_id': '999',
      'student_name': 'New Child',
    });

    expect(updated?.selectedStudentId, 999);
    expect(updated?.selectedStudentName, 'New Child');
  });

  test('decodes the notification payload json', () {
    final encoded = NotificationRouter.encodePayload({
      'kind': 'special_remark',
      'student_id': '297',
    });
    final decoded = NotificationRouter.decodePayload(encoded);
    expect(decoded?['kind'], 'special_remark');
    expect(NotificationRouter.studentIdOf(decoded!), 297);
  });

  test('fee collection tap opens the fee vouchers screen', () {
    expect(
      NotificationRouter.targetRoute({
        'kind': 'fee_collection',
        'student_id': '297',
      }),
      AppRoutes.parentFeeVouchers,
    );
    expect(
      NotificationRouter.isFeeCollection({'kind': 'fee_collection'}),
      isTrue,
    );
    expect(
      NotificationRouter.targetRoute({'kind': 'special_remark'}),
      AppRoutes.parentSpecialRemarks,
    );
    expect(
      NotificationRouter.targetRoute({'kind': 'attendance'}),
      isNull,
    );
  });

  test('announcement tap opens the parent dashboard once', () {
    expect(
      NotificationRouter.targetRoute({
        'kind': 'announcement',
        'announcement_id': '12',
        'branch_id': '1',
      }),
      AppRoutes.parentDashboard,
    );
    expect(
      NotificationRouter.isAnnouncement({'kind': 'announcement'}),
      isTrue,
    );
    expect(
      NotificationRouter.applyStudent(_parentWithChildren(), {
        'kind': 'announcement',
        'announcement_id': '12',
      })?.selectedStudentId,
      isNull,
    );
  });

  test('teacher announcement tap opens the teacher dashboard', () {
    expect(
      NotificationRouter.targetRoute({
        'kind': 'announcement',
        'route': 'teacher_dashboard',
        'audience': 'teachers',
        'branch_id': '2',
      }),
      AppRoutes.teacherDashboard,
    );

    final session = AuthSession.fromJson({
      'token': 'teacher.token',
      'token_type': 'Bearer',
      'type': 'teacher',
      'school': {'id': '1', 'name': 'SLS', 'domain': 'sls.localhost'},
      'user': {'id': 58, 'name': 'Sara', 'roles': ['Teacher']},
      'profile': {
        'type': 'teacher',
        'teacher_id': 4,
        'branch_id': 1,
        'branch_name': 'Avicenna Campus',
        'branches': [
          {'branch_id': 1, 'branch_name': 'Avicenna Campus'},
          {'branch_id': 2, 'branch_name': 'Ibn Sina Campus'},
        ],
      },
    });

    final updated = NotificationRouter.applyBranch(session, {
      'kind': 'announcement',
      'branch_id': '2',
    });
    expect(updated?.selectedBranchId, 2);
    expect(updated?.selectedBranchName, 'Ibn Sina Campus');
  });

  test('salary paid tap opens the teacher dashboard without an amount', () {
    final payload = {
      'kind': 'salary_paid',
      'route': 'teacher_dashboard',
      'month_label': 'September 2026',
      'paid_at': '02 Oct 2026, 07:17 PM',
      'paid_by': 'Tanveer Admin',
      'branch_id': '1',
    };

    expect(NotificationRouter.targetRoute(payload), AppRoutes.teacherDashboard);
    expect(NotificationRouter.isSalaryPaid(payload), isTrue);
    expect(NotificationRouter.encodePayload(payload), isNot(contains('PKR')));
    expect(NotificationRouter.encodePayload(payload), isNot(contains('amount')));
  });
}
