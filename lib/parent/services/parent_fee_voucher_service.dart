import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../models/auth_session.dart';
import '../models/parent_fee_vouchers.dart';

class ParentFeeVoucherQuery {
  const ParentFeeVoucherQuery({
    this.tab = 'unpaid',
    this.page = 1,
    this.perPage = 25,
  });

  final String tab;
  final int page;
  final int perPage;
}

class ParentFeeVoucherService {
  ParentFeeVoucherService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<ParentFeeVoucherData> fetch(
    AuthSession session, {
    ParentFeeVoucherQuery query = const ParentFeeVoucherQuery(),
  }) async {
    final domain = session.school?.domain?.trim() ?? '';
    if (domain.isEmpty) {
      throw const ApiException('School domain is missing. Please sign in again.');
    }

    final studentId = session.selectedStudentId;
    if (studentId == null) {
      throw const ApiException('Select a student to view fee vouchers.');
    }

    final json = await _client.get(
      ApiEndpoints.parentStudentFeeVouchers,
      token: session.token,
      query: {
        'domain': domain,
        'student_id': '$studentId',
        'tab': query.tab,
        'page': '${query.page}',
        'per_page': '${query.perPage}',
      },
    );

    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Unexpected fee vouchers response.');
    }

    return ParentFeeVoucherData.fromJson(
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
