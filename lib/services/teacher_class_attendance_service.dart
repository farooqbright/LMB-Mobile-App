import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/auth_session.dart';
import '../models/teacher_class_attendance.dart';

class TeacherClassAttendanceService {
  TeacherClassAttendanceService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Map<String, String> _baseQuery(AuthSession session) {
    final domain = session.school?.domain?.trim() ?? '';
    if (domain.isEmpty) {
      throw const ApiException('School domain is missing. Please sign in again.');
    }

    final branchId = session.activeBranchId;
    if (branchId == null || branchId < 1) {
      throw const ApiException('Select a branch to mark class attendance.');
    }

    return {
      'domain': domain,
      'branch_id': '$branchId',
    };
  }

  Future<TeacherClassAttendanceClasses> fetchClasses(AuthSession session) async {
    final json = await _client.get(
      ApiEndpoints.teacherClassAttendanceClasses,
      token: session.token,
      query: _baseQuery(session),
    );

    return TeacherClassAttendanceClasses.fromJson(_dataMap(json));
  }

  Future<TeacherClassAttendanceMark> fetchMark(
    AuthSession session, {
    required ClassAttendanceClass classItem,
    required ClassAttendanceSection section,
    required String date,
  }) async {
    final json = await _client.get(
      ApiEndpoints.teacherClassAttendanceMark,
      token: session.token,
      query: {
        ..._baseQuery(session),
        'academic_session_id': '${classItem.academicSessionId}',
        'class_id': '${classItem.classId}',
        'class_section_id': '${section.classSectionId}',
        'date': date,
      },
    );

    return TeacherClassAttendanceMark.fromJson(_dataMap(json));
  }

  Future<TeacherClassAttendanceSaveResult> save(
    AuthSession session, {
    required ClassAttendanceClass classItem,
    required ClassAttendanceSection section,
    required String date,
    required List<ClassAttendanceStudent> students,
  }) async {
    final json = await _client.post(
      ApiEndpoints.teacherClassAttendanceStore,
      token: session.token,
      body: {
        ..._baseQuery(session),
        'academic_session_id': classItem.academicSessionId,
        'class_id': classItem.classId,
        'class_section_id': section.classSectionId,
        'date': date,
        'attendance': {
          for (final student in students)
            '${student.id}': {'status': student.status},
        },
      },
    );

    final data = json['data'];
    return TeacherClassAttendanceSaveResult(
      saved: data is Map ? _asSaved(data['saved']) : 0,
      message: json['message'] is String ? json['message'] as String : null,
    );
  }

  Map<String, dynamic> _dataMap(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ApiException('Unexpected class attendance response.');
  }

  int _asSaved(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
