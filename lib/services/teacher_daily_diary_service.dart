import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/auth_session.dart';
import '../models/teacher_daily_diary.dart';

class TeacherDailyDiaryService {
  TeacherDailyDiaryService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Map<String, String> _baseQuery(AuthSession session) {
    final domain = session.school?.domain?.trim() ?? '';
    if (domain.isEmpty) {
      throw const ApiException('School domain is missing. Please sign in again.');
    }

    final branchId = session.activeBranchId;
    if (branchId == null || branchId < 1) {
      throw const ApiException('Select a branch to add a daily diary.');
    }

    return {
      'domain': domain,
      'branch_id': '$branchId',
    };
  }

  Future<TeacherDailyDiaryClasses> fetchClasses(AuthSession session) async {
    final json = await _client.get(
      ApiEndpoints.teacherDailyDiaryClasses,
      token: session.token,
      query: _baseQuery(session),
    );

    return TeacherDailyDiaryClasses.fromJson(_dataMap(json));
  }

  Future<TeacherDailyDiarySubjects> fetchSubjects(
    AuthSession session, {
    required DiaryClass classItem,
    required DiarySection section,
  }) async {
    final json = await _client.get(
      ApiEndpoints.teacherDailyDiarySubjects,
      token: session.token,
      query: {
        ..._baseQuery(session),
        'academic_session_id': '${classItem.academicSessionId}',
        'class_id': '${classItem.classId}',
        'class_section_id': '${section.classSectionId}',
      },
    );

    return TeacherDailyDiarySubjects.fromJson(_dataMap(json));
  }

  Future<TeacherDailyDiaryEntry> fetchEntry(
    AuthSession session, {
    required DiaryClass classItem,
    required DiarySection section,
    required DiarySubject subject,
    required String date,
  }) async {
    final json = await _client.get(
      ApiEndpoints.teacherDailyDiaryEntry,
      token: session.token,
      query: {
        ..._baseQuery(session),
        'academic_session_id': '${classItem.academicSessionId}',
        'class_id': '${classItem.classId}',
        'class_section_id': '${section.classSectionId}',
        'subject_id': '${subject.subjectId}',
        'date': date,
      },
    );

    return TeacherDailyDiaryEntry.fromJson(_dataMap(json));
  }

  Future<TeacherDailyDiarySaveResult> save(
    AuthSession session, {
    required DiaryClass classItem,
    required DiarySection section,
    required DiarySubject subject,
    required String date,
    required List<int> sectionIds,
    String? workDone,
    String? homework,
    String? remarks,
  }) async {
    final base = _baseQuery(session);
    final json = await _client.post(
      ApiEndpoints.teacherDailyDiaryStore,
      token: session.token,
      body: {
        ...base,
        'academic_session_id': classItem.academicSessionId,
        'class_id': classItem.classId,
        'class_section_id': section.classSectionId,
        'class_section_ids': sectionIds,
        'subject_id': subject.subjectId,
        'diary_date': date,
        'work_done': _blankToNull(workDone),
        'homework': _blankToNull(homework),
        'remarks': _blankToNull(remarks),
      },
    );

    final data = json['data'];
    final saved = data is Map ? _asSaved(data['saved']) : 0;
    return TeacherDailyDiarySaveResult(
      saved: saved,
      message: json['message'] is String ? json['message'] as String : null,
    );
  }

  Map<String, dynamic> _dataMap(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ApiException('Unexpected daily diary response.');
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
