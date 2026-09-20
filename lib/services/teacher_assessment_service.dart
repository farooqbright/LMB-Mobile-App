import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/auth_session.dart';
import '../models/teacher_assessment.dart';

class TeacherAssessmentService {
  TeacherAssessmentService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Map<String, String> _baseQuery(AuthSession session) {
    final domain = session.school?.domain?.trim() ?? '';
    if (domain.isEmpty) {
      throw const ApiException('School domain is missing. Please sign in again.');
    }

    final branchId = session.activeBranchId;
    if (branchId == null || branchId < 1) {
      throw const ApiException('Select a branch to add tests and homework.');
    }

    return {
      'domain': domain,
      'branch_id': '$branchId',
    };
  }

  Future<TeacherAssessmentClasses> fetchClasses(AuthSession session) async {
    final json = await _client.get(
      ApiEndpoints.teacherAssessmentClasses,
      token: session.token,
      query: _baseQuery(session),
    );

    return TeacherAssessmentClasses.fromJson(_dataMap(json));
  }

  Future<TeacherAssessmentSectionData> fetchSection(
    AuthSession session, {
    required AssessmentClass classItem,
    required AssessmentSection section,
    int page = 1,
    int perPage = 25,
  }) async {
    final json = await _client.get(
      ApiEndpoints.teacherAssessmentSubjects,
      token: session.token,
      query: {
        ..._baseQuery(session),
        'academic_session_id': '${classItem.academicSessionId}',
        'class_id': '${classItem.classId}',
        'class_section_id': '${section.classSectionId}',
        'page': '$page',
        'per_page': '$perPage',
      },
    );

    return TeacherAssessmentSectionData.fromJson(
      _dataMap(json),
      metaJson: _asMap(json['meta']),
    );
  }

  Future<TeacherAssessmentSaveResult> save(
    AuthSession session, {
    required AssessmentClass classItem,
    required AssessmentSection section,
    required AssessmentSubject subject,
    TeacherAssessment? existing,
    required String type,
    required String title,
    String? description,
    required String assessmentDate,
    String? dueDate,
    int? totalMarks,
    String? remarks,
  }) async {
    final json = await _client.post(
      existing == null
          ? ApiEndpoints.teacherAssessmentStore
          : ApiEndpoints.teacherAssessmentUpdate,
      token: session.token,
      body: {
        ..._baseQuery(session),
        if (existing != null) 'assessment_id': existing.id,
        'academic_session_id': classItem.academicSessionId,
        'class_id': classItem.classId,
        'class_section_id': section.classSectionId,
        'subject_id': subject.subjectId,
        'type': type,
        'title': title.trim(),
        'description': _blankToNull(description),
        'assessment_date': assessmentDate,
        'due_date': _blankToNull(dueDate),
        'total_marks': totalMarks,
        'remarks': _blankToNull(remarks),
      },
    );

    final data = _asMap(json['data']);
    final assessment = data?['assessment'];
    return TeacherAssessmentSaveResult(
      message: json['message'] is String ? json['message'] as String : null,
      assessment: assessment is Map
          ? TeacherAssessment.fromJson(Map<String, dynamic>.from(assessment))
          : existing,
    );
  }

  Future<TeacherAssessmentSaveResult> delete(
    AuthSession session, {
    required int assessmentId,
  }) async {
    final json = await _client.post(
      ApiEndpoints.teacherAssessmentDelete,
      token: session.token,
      body: {
        ..._baseQuery(session),
        'assessment_id': assessmentId,
      },
    );

    return TeacherAssessmentSaveResult(
      message: json['message'] is String ? json['message'] as String : null,
    );
  }

  Future<TeacherAssessmentMarks> fetchMarks(
    AuthSession session, {
    required int assessmentId,
  }) async {
    final json = await _client.get(
      ApiEndpoints.teacherAssessmentMarks,
      token: session.token,
      query: {
        ..._baseQuery(session),
        'assessment_id': '$assessmentId',
      },
    );

    return TeacherAssessmentMarks.fromJson(_dataMap(json));
  }

  Future<TeacherAssessmentSaveResult> saveMarks(
    AuthSession session, {
    required int assessmentId,
    required List<Map<String, dynamic>> entries,
  }) async {
    final json = await _client.post(
      ApiEndpoints.teacherAssessmentMarksStore,
      token: session.token,
      body: {
        ..._baseQuery(session),
        'assessment_id': assessmentId,
        'entries': entries,
      },
    );

    final data = json['data'];
    return TeacherAssessmentSaveResult(
      saved: data is Map ? _asSaved(data['saved']) : 0,
      message: json['message'] is String ? json['message'] as String : null,
    );
  }

  Map<String, dynamic> _dataMap(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ApiException('Unexpected tests and homework response.');
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  String? _blankToNull(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }

  int _asSaved(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
