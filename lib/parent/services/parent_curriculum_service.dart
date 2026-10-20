import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../models/auth_session.dart';
import '../../models/teacher_curriculum.dart';
import '../models/parent_curriculum.dart';

class ParentCurriculumService {
  ParentCurriculumService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Map<String, String> _baseQuery(AuthSession session) {
    final domain = session.school?.domain?.trim() ?? '';
    if (domain.isEmpty) {
      throw const ApiException('School domain is missing. Please sign in again.');
    }

    final studentId = session.selectedStudentId;
    if (studentId == null) {
      throw const ApiException('Select a student to view the curriculum.');
    }

    return {
      'domain': domain,
      'student_id': '$studentId',
    };
  }

  Future<ParentCurriculumSubjects> fetchSubjects(AuthSession session) async {
    final json = await _client.get(
      ApiEndpoints.parentStudentCurriculum,
      token: session.token,
      query: _baseQuery(session),
    );

    return ParentCurriculumSubjects.fromJson(_dataMap(json));
  }

  Future<TeacherCurriculumWeeks> fetchWeeks(
    AuthSession session, {
    required int subjectId,
    String tab = 'open',
  }) async {
    final json = await _client.get(
      ApiEndpoints.parentStudentCurriculumShow,
      token: session.token,
      query: {
        ..._baseQuery(session),
        'subject_id': '$subjectId',
        'tab': tab,
      },
    );

    return TeacherCurriculumWeeks.fromJson(_dataMap(json));
  }

  Map<String, dynamic> _dataMap(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ApiException('Unexpected curriculum response.');
  }
}
