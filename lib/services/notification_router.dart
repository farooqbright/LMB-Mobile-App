import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/routes.dart';
import '../models/auth_session.dart';
import '../parent/models/parent_fee_vouchers.dart';
import '../parent/screens/parent_fee_vouchers_view.dart';
import '../views/salary/teacher_salary_view.dart';
import 'session_store.dart';

class NotificationRouter {
  NotificationRouter._();

  static final NotificationRouter instance = NotificationRouter._();

  static const pendingKey = 'pending_push_payload';
  static const kindSpecialRemark = 'special_remark';
  static const kindFeeCollection = 'fee_collection';
  static const kindAnnouncement = 'announcement';
  static const kindSalaryPaid = 'salary_paid';

  GlobalKey<NavigatorState>? navigatorKey;

  Future<void> handleData(Map<String, dynamic> data) async {
    if (targetRoute(data) == null) return;
    await _storePending(data);
    await openPending();
  }

  Future<void> handlePayload(String? payload) async {
    final data = decodePayload(payload);
    if (data == null) return;
    await handleData(data);
  }

  Future<bool> openPending({NavigatorState? navigator}) async {
    final data = await _readPending();
    if (data == null) return false;

    var session = SessionStore.instance.current;
    session ??= await SessionStore.instance.restore();
    if (session == null) return false;

    final nav = navigator ?? navigatorKey?.currentState;
    if (nav == null) return false;

    if (session.isTeacher) {
      if (!isTeacherDashboardPush(data)) return false;
      final opened = applyBranch(session, data) ?? session;
      await SessionStore.instance.update(opened);
      await _clearPending();
      nav.pushNamedAndRemoveUntil(
        AppRoutes.teacherDashboard,
        (_) => false,
        arguments: opened,
      );
      if (isSalaryPaid(data) && opened.showTeacherMonthlySalary) {
        nav.push(
          MaterialPageRoute(
            settings: const RouteSettings(name: AppRoutes.teacherSalary),
            builder: (_) => TeacherSalaryView(session: opened),
          ),
        );
      }
      return true;
    }

    if (!session.isParent) return false;

    final opened = applyStudent(session, data) ?? session;
    await SessionStore.instance.update(opened);

    await _clearPending();
    nav.pushNamedAndRemoveUntil(
      AppRoutes.parentDashboard,
      (_) => false,
      arguments: opened,
    );
    if (isFeeCollection(data) && opened.showParentFeeVouchers) {
      nav.push(
        MaterialPageRoute(
          settings: const RouteSettings(name: AppRoutes.parentFeeVouchers),
          builder: (_) => ParentFeeVouchersView(
            session: opened,
            initialTab: ParentFeeVoucherTab.invoices,
          ),
        ),
      );
    } else if (!isAnnouncement(data) && !isFeeCollection(data)) {
      nav.pushNamed(
        AppRoutes.parentSpecialRemarks,
        arguments: opened,
      );
    }
    return true;
  }

  static String? targetRoute(Map<String, dynamic> data) {
    if (!_isSupported(data)) return null;
    if (isFeeCollection(data)) return AppRoutes.parentFeeVouchers;
    if (isSalaryPaid(data) || _isTeacherAnnouncement(data)) {
      return AppRoutes.teacherDashboard;
    }
    if (isAnnouncement(data)) {
      return AppRoutes.parentDashboard;
    }
    return AppRoutes.parentSpecialRemarks;
  }

  static bool isFeeCollection(Map<String, dynamic> data) {
    final kind = '${data['kind'] ?? ''}'.trim();
    return kind == kindFeeCollection || kind == 'fee_receipt';
  }

  static bool isAnnouncement(Map<String, dynamic> data) {
    return '${data['kind'] ?? ''}'.trim() == kindAnnouncement;
  }

  static bool isSalaryPaid(Map<String, dynamic> data) {
    return '${data['kind'] ?? ''}'.trim() == kindSalaryPaid;
  }

  static bool isTeacherDashboardPush(Map<String, dynamic> data) {
    return isSalaryPaid(data) || _isTeacherAnnouncement(data);
  }

  static bool _isTeacherAnnouncement(Map<String, dynamic> data) {
    if (!isAnnouncement(data)) return false;
    final route = '${data['route'] ?? data['audience'] ?? ''}'.trim();
    return route == 'teacher_dashboard' ||
        route == 'teacher_salary' ||
        route == 'teachers';
  }

  static AuthSession? applyBranch(
    AuthSession session,
    Map<String, dynamic> data,
  ) {
    if (!session.isTeacher) return null;
    final branchId = int.tryParse('${data['branch_id'] ?? ''}'.trim());
    if (branchId == null) return session;
    for (final branch in session.teacherBranches) {
      if (branch.branchId == branchId) {
        return session.withBranch(branch);
      }
    }
    return session;
  }

  static AuthSession? applyStudent(
    AuthSession session,
    Map<String, dynamic> data,
  ) {
    if (!session.isParent) return null;
    final studentId = studentIdOf(data);
    if (studentId == null) return session;
    for (final child in session.parentChildren) {
      if (child.studentId == studentId) {
        return session.withStudent(child);
      }
    }
    final name = '${data['student_name'] ?? ''}'.trim();
    return session.withStudent(
      ParentChild(
        studentId: studentId,
        fullName: name.isEmpty ? null : name,
      ),
    );
  }

  static int? studentIdOf(Map<String, dynamic> data) {
    return int.tryParse('${data['student_id'] ?? ''}'.trim());
  }

  static Map<String, dynamic>? decodePayload(String? payload) {
    final raw = payload?.trim() ?? '';
    if (raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return null;
  }

  static String encodePayload(Map<String, dynamic> data) => jsonEncode(data);

  static bool _isSupported(Map<String, dynamic> data) {
    final kind = '${data['kind'] ?? ''}'.trim();
    return kind.isEmpty ||
        kind == kindSpecialRemark ||
        isFeeCollection(data) ||
        isAnnouncement(data) ||
        isSalaryPaid(data);
  }

  Future<void> _storePending(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(pendingKey, jsonEncode(data));
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> _readPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return decodePayload(prefs.getString(pendingKey));
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(pendingKey);
    } catch (_) {}
  }
}
