import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/auth_session.dart';
import '../models/teacher_attendance.dart';

class TeacherAttendanceQuery {
  const TeacherAttendanceQuery({
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

  TeacherAttendanceQuery copyWith({
    String? status,
    String? dateFrom,
    String? dateTo,
    int? page,
    int? perPage,
  }) {
    return TeacherAttendanceQuery(
      status: status ?? this.status,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
    );
  }
}

class TeacherAttendanceService {
  TeacherAttendanceService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<TeacherAttendanceData> fetch(
    AuthSession session, {
    TeacherAttendanceQuery query = const TeacherAttendanceQuery(),
  }) async {
    final domain = session.school?.domain?.trim() ?? '';
    if (domain.isEmpty) {
      throw const ApiException('School domain is missing. Please sign in again.');
    }

    final json = await _client.get(
      ApiEndpoints.teacherMyAttendance,
      token: session.token,
      query: {
        'domain': domain,
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

    return TeacherAttendanceData.fromJson(
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
