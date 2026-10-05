import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../models/auth_session.dart';
import '../models/parent_special_remarks.dart';

class ParentSpecialRemarksQuery {
  const ParentSpecialRemarksQuery({
    this.period = 'today',
    this.date,
    this.page = 1,
    this.perPage = 25,
  });

  final String period;
  final String? date;
  final int page;
  final int perPage;
}

class ParentSpecialRemarksService {
  ParentSpecialRemarksService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<ParentSpecialRemarksData> fetch(
    AuthSession session, {
    ParentSpecialRemarksQuery query = const ParentSpecialRemarksQuery(),
  }) async {
    final domain = session.school?.domain?.trim() ?? '';
    if (domain.isEmpty) {
      throw const ApiException('School domain is missing. Please sign in again.');
    }

    final studentId = session.selectedStudentId ??
        (session.parentChildren.isNotEmpty
            ? session.parentChildren.first.studentId
            : null);
    if (studentId == null || studentId < 1) {
      throw const ApiException('Select a student to view special remarks.');
    }

    final date = (query.date ?? '').trim();
    final json = await _client.get(
      ApiEndpoints.parentStudentSpecialRemarks,
      token: session.token,
      query: {
        'domain': domain,
        'student_id': '$studentId',
        'period': query.period,
        if (date.isNotEmpty) 'date': date,
        'page': '${query.page}',
        'per_page': '${query.perPage}',
      },
    );

    final data = _asMap(json['data']);
    if (data == null) {
      throw const ApiException('Unexpected special remarks response.');
    }

    return ParentSpecialRemarksData.fromJson(
      data,
      metaJson: _asMap(json['meta']) ?? _asMap(data['meta']),
    );
  }
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}
