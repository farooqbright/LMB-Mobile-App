import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/auth_session.dart';
import '../models/teacher_salary.dart';

class TeacherSalaryService {
  TeacherSalaryService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<TeacherSalaryData> fetch(
    AuthSession session, {
    int page = 1,
    int perPage = 25,
  }) async {
    final credentials = _credentials(session);
    final json = await _client.get(
      ApiEndpoints.teacherMySalary,
      token: session.token,
      query: {
        ...credentials,
        'page': '$page',
        'per_page': '$perPage',
      },
    );

    final data = json['data'];
    if (data is! Map) {
      throw const ApiException('Unexpected salary slips response.');
    }

    return TeacherSalaryData.fromJson(
      Map<String, dynamic>.from(data),
      metaJson: _asMap(json['meta']) ?? _asMap(data['meta']),
    );
  }

  Future<TeacherSalaryItem> fetchSlip(AuthSession session, int itemId) async {
    final credentials = _credentials(session);
    final json = await _client.get(
      ApiEndpoints.teacherMySalaryShow,
      token: session.token,
      query: {
        ...credentials,
        'item_id': '$itemId',
      },
    );

    final data = json['data'];
    if (data is! Map) {
      throw const ApiException('Unexpected salary slip response.');
    }

    final slip = data['slip'];
    if (slip is! Map) {
      throw const ApiException('Salary slip details are missing.');
    }

    return TeacherSalaryItem.fromJson(Map<String, dynamic>.from(slip));
  }

  Map<String, String> _credentials(AuthSession session) {
    final domain = session.school?.domain?.trim() ?? '';
    if (domain.isEmpty) {
      throw const ApiException('School domain is missing. Please sign in again.');
    }

    final branchId = session.activeBranchId;
    if (branchId == null || branchId < 1) {
      throw const ApiException('Select a branch to view salary slips.');
    }

    return {
      'domain': domain,
      'branch_id': '$branchId',
    };
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}
