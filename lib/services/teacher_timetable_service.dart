import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/auth_session.dart';
import '../models/teacher_timetable.dart';

class TeacherTimetableService {
  TeacherTimetableService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<TeacherTimetableData> fetch(AuthSession session) async {
    final domain = session.school?.domain?.trim() ?? '';
    if (domain.isEmpty) {
      throw const ApiException('School domain is missing. Please sign in again.');
    }

    final branchId = session.activeBranchId;
    if (branchId == null || branchId < 1) {
      throw const ApiException('Select a branch to view your timetable.');
    }

    final json = await _client.get(
      ApiEndpoints.teacherMyTimetable,
      token: session.token,
      query: {
        'domain': domain,
        'branch_id': '$branchId',
      },
    );

    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Unexpected timetable response.');
    }

    return TeacherTimetableData.fromJson(data, branchId: branchId)
        .forBranch(branchId);
  }
}
