import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../models/auth_session.dart';
import '../models/parent_attendance.dart';

class ParentAttendanceQuery {
  const ParentAttendanceQuery({
    this.status,
    this.dateFrom,
    this.dateTo,
    this.page = 1,
    this.perPage = 25,
  });

  final String? status;
  final String? dateFrom;
  final String? dateTo;
  final int page;
  final int perPage;

  ParentAttendanceQuery copyWith({
    String? status,
    String? dateFrom,
    String? dateTo,
    int? page,
    int? perPage,
  }) {
    return ParentAttendanceQuery(
      status: status ?? this.status,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
    );
  }
}

class ParentAttendanceService {
  ParentAttendanceService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<ParentAttendanceData> fetch(
    AuthSession session, {
    ParentAttendanceQuery query = const ParentAttendanceQuery(),
  }) async {
    final domain = session.school?.domain?.trim() ?? '';
    if (domain.isEmpty) {
      throw const ApiException('School domain is missing. Please sign in again.');
    }

    final studentId = session.selectedStudentId;
    if (studentId == null) {
      throw const ApiException('Select a student to view attendance.');
    }

    final json = await _client.get(
      ApiEndpoints.parentStudentAttendance,
      token: session.token,
      query: {
        'domain': domain,
        'student_id': '$studentId',
        'page': '${query.page}',
        'per_page': '${query.perPage}',
        if (query.status != null && query.status!.isNotEmpty) 'status': query.status!,
        if (query.dateFrom != null && query.dateFrom!.isNotEmpty) 'date_from': query.dateFrom!,
        if (query.dateTo != null && query.dateTo!.isNotEmpty) 'date_to': query.dateTo!,
      },
    );

    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Unexpected attendance response.');
    }

    return ParentAttendanceData.fromJson(
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
