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

  Future<BranchGeoFence> fetchLocation(AuthSession session) async {
    final json = await _client.get(
      ApiEndpoints.teacherMyAttendanceLocation,
      token: session.token,
      query: _credentials(session),
    );

    final data = json['data'];
    if (data is! Map<String, dynamic> && data is! Map) {
      throw const ApiException('Unexpected school location response.');
    }

    return BranchGeoFence.fromJson(_asMap(data) ?? const {});
  }

  Future<TeacherAttendanceMarkResult> markAttendance(
    AuthSession session, {
    required double latitude,
    required double longitude,
  }) async {
    final credentials = _credentials(session);
    final json = await _client.post(
      ApiEndpoints.teacherMyAttendanceMark,
      token: session.token,
      body: {
        'domain': credentials['domain'],
        'branch_id': int.parse(credentials['branch_id']!),
        'latitude': latitude,
        'longitude': longitude,
      },
    );

    final data = _asMap(json['data']) ?? const <String, dynamic>{};
    return TeacherAttendanceMarkResult.fromJson(
      data,
      message: json['message'] is String ? json['message'] as String : null,
    );
  }

  Map<String, String> _credentials(AuthSession session) {
    final domain = session.school?.domain?.trim() ?? '';
    if (domain.isEmpty) {
      throw const ApiException('School domain is missing. Please sign in again.');
    }

    final branchId = session.activeBranchId;
    if (branchId == null || branchId < 1) {
      throw const ApiException('Select a branch to mark attendance.');
    }

    return {
      'domain': domain,
      'branch_id': '$branchId',
    };
  }
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}
