import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/auth_session.dart';
import '../models/school_announcement.dart';

class AnnouncementService {
  AnnouncementService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<SchoolAnnouncement>> fetchForTeacher(AuthSession session) async {
    final domain = session.school?.domain?.trim() ?? '';
    if (domain.isEmpty) {
      throw const ApiException('School domain is missing. Please sign in again.');
    }

    final branchId = session.activeBranchId;
    if (branchId == null || branchId < 1) {
      throw const ApiException('Select a branch to view announcements.');
    }

    final json = await _client.get(
      ApiEndpoints.teacherAnnouncements,
      token: session.token,
      query: {
        'domain': domain,
        'branch_id': '$branchId',
      },
    );

    return _parseList(json);
  }

  Future<List<SchoolAnnouncement>> fetchForParent(AuthSession session) async {
    final domain = session.school?.domain?.trim() ?? '';
    if (domain.isEmpty) {
      throw const ApiException('School domain is missing. Please sign in again.');
    }

    final studentId = session.selectedStudentId;
    final json = await _client.get(
      ApiEndpoints.parentAnnouncements,
      token: session.token,
      query: {
        'domain': domain,
        if (studentId != null && studentId > 0) 'student_id': '$studentId',
      },
    );

    return _parseList(json);
  }

  List<SchoolAnnouncement> _parseList(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Unexpected announcements response.');
    }

    final raw = data['announcements'];
    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<Map>()
        .map((row) => SchoolAnnouncement.fromJson(Map<String, dynamic>.from(row)))
        .where((row) => row.id > 0 && row.title.isNotEmpty)
        .toList(growable: false);
  }
}
