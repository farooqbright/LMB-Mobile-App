import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../models/auth_session.dart';
import '../models/parent_timetable.dart';

class ParentTimetableService {
  ParentTimetableService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<ParentTimetableData> fetch(AuthSession session) async {
    final domain = session.school?.domain?.trim() ?? '';
    if (domain.isEmpty) {
      throw const ApiException('School domain is missing. Please sign in again.');
    }

    final studentId = session.selectedStudentId;
    if (studentId == null) {
      throw const ApiException('Select a student to view the timetable.');
    }

    final json = await _client.get(
      ApiEndpoints.parentStudentTimetable,
      token: session.token,
      query: {
        'domain': domain,
        'student_id': '$studentId',
      },
    );

    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Unexpected timetable response.');
    }

    return ParentTimetableData.fromJson(data);
  }
}
