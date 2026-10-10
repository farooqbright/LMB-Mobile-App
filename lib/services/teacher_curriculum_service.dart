import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/auth_session.dart';
import '../models/teacher_curriculum.dart';

class TeacherCurriculumService {
  TeacherCurriculumService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Map<String, String> _baseQuery(AuthSession session) {
    final domain = session.school?.domain?.trim() ?? '';
    if (domain.isEmpty) {
      throw const ApiException('School domain is missing. Please sign in again.');
    }

    final branchId = session.activeBranchId;
    if (branchId == null || branchId < 1) {
      throw const ApiException('Select a branch to open My Weeks.');
    }

    return {
      'domain': domain,
      'branch_id': '$branchId',
    };
  }

  Future<TeacherCurriculumSubjects> fetchSubjects(AuthSession session) async {
    final json = await _client.get(
      ApiEndpoints.teacherCurriculumSubjects,
      token: session.token,
      query: _baseQuery(session),
    );

    return TeacherCurriculumSubjects.fromJson(_dataMap(json));
  }

  Future<TeacherCurriculumWeeks> fetchWeeks(
    AuthSession session, {
    required CurriculumSubjectSelection selection,
    String tab = 'open',
  }) async {
    final json = await _client.get(
      ApiEndpoints.teacherCurriculumWeeks,
      token: session.token,
      query: {
        ..._baseQuery(session),
        if (selection.subject.academicSessionId > 0)
          'session_id': '${selection.subject.academicSessionId}',
        'class_id': '${selection.classItem.classId}',
        'class_section_id': '${selection.section.classSectionId}',
        'subject_id': '${selection.subject.subjectId}',
        'tab': tab,
      },
    );

    return TeacherCurriculumWeeks.fromJson(_dataMap(json));
  }

  Future<CurriculumWeekUpdateResult> updateWeek(
    AuthSession session, {
    required int completionId,
    required String status,
    String? notes,
  }) async {
    final json = await _client.post(
      ApiEndpoints.teacherCurriculumWeekUpdate,
      token: session.token,
      body: {
        ..._baseQuery(session),
        'completion_id': completionId,
        'status': status,
        'notes': _blankToNull(notes),
      },
    );

    final data = json['data'];
    final map = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
    return CurriculumWeekUpdateResult.fromJson(
      map,
      message: json['message'] is String ? json['message'] as String : null,
    );
  }

  Map<String, dynamic> _dataMap(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ApiException('Unexpected curriculum response.');
  }

  String? _blankToNull(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
