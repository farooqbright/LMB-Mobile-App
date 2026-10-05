import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/auth_session.dart';
import '../models/teacher_exam.dart';

class TeacherExamService {
  TeacherExamService({
    ApiClient? client,
    this.listPath = ApiEndpoints.teacherExams,
    this.showPath = ApiEndpoints.teacherExamShow,
    this.marksPath = ApiEndpoints.teacherExamMarks,
    this.marksStorePath = ApiEndpoints.teacherExamMarksStore,
    this.idKey = 'exam_id',
    this.missingBranchMessage = 'Select a branch to enter exam marks.',
    this.unexpectedResponseMessage = 'Unexpected exam response.',
  }) : _client = client ?? ApiClient();

  final ApiClient _client;
  final String listPath;
  final String showPath;
  final String marksPath;
  final String marksStorePath;
  final String idKey;
  final String missingBranchMessage;
  final String unexpectedResponseMessage;

  Map<String, String> _baseQuery(AuthSession session) {
    final domain = session.school?.domain?.trim() ?? '';
    if (domain.isEmpty) {
      throw const ApiException('School domain is missing. Please sign in again.');
    }

    final branchId = session.activeBranchId;
    if (branchId == null || branchId < 1) {
      throw ApiException(missingBranchMessage);
    }

    return {
      'domain': domain,
      'branch_id': '$branchId',
    };
  }

  Future<TeacherExamList> fetchExams(
    AuthSession session, {
    int? academicSessionId,
    int page = 1,
    int perPage = 25,
  }) async {
    final json = await _client.get(
      listPath,
      token: session.token,
      query: {
        ..._baseQuery(session),
        if (academicSessionId != null && academicSessionId > 0)
          'academic_session_id': '$academicSessionId',
        'page': '$page',
        'per_page': '$perPage',
      },
    );

    return TeacherExamList.fromJson(
      _dataMap(json),
      metaJson: json['meta'] is Map ? Map<String, dynamic>.from(json['meta'] as Map) : null,
    );
  }

  Future<TeacherExamSummary> fetchExam(
    AuthSession session, {
    required int examId,
  }) async {
    final json = await _client.get(
      showPath,
      token: session.token,
      query: {
        ..._baseQuery(session),
        idKey: '$examId',
      },
    );

    final data = _dataMap(json);
    final exam = data['exam'];
    if (exam is Map<String, dynamic>) {
      return TeacherExamSummary.fromJson(exam);
    }
    if (exam is Map) {
      return TeacherExamSummary.fromJson(Map<String, dynamic>.from(exam));
    }
    throw ApiException(unexpectedResponseMessage);
  }

  Future<TeacherExamMarksGrid> fetchMarks(
    AuthSession session, {
    required int examId,
    required int datesheetId,
    required int classId,
    required int classSectionId,
  }) async {
    final json = await _client.get(
      marksPath,
      token: session.token,
      query: {
        ..._baseQuery(session),
        idKey: '$examId',
        'datesheet_id': '$datesheetId',
        'class_id': '$classId',
        'class_section_id': '$classSectionId',
      },
    );

    return TeacherExamMarksGrid.fromJson(_dataMap(json));
  }

  Future<TeacherExamSaveResult> saveMarks(
    AuthSession session, {
    required int examId,
    required int datesheetId,
    required int classId,
    required int classSectionId,
    required List<Map<String, dynamic>> totals,
    required List<Map<String, dynamic>> entries,
  }) async {
    final json = await _client.post(
      marksStorePath,
      token: session.token,
      body: {
        ..._baseQuery(session),
        idKey: examId,
        'datesheet_id': datesheetId,
        'class_id': classId,
        'class_section_id': classSectionId,
        'totals': totals,
        'entries': entries,
      },
    );

    final data = json['data'];
    return TeacherExamSaveResult(
      saved: data is Map ? _asSaved(data['saved']) : 0,
      message: json['message'] is String ? json['message'] as String : null,
    );
  }

  Map<String, dynamic> _dataMap(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException(unexpectedResponseMessage);
  }

  int _asSaved(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
