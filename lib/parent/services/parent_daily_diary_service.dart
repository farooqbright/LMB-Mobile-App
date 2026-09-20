import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../models/auth_session.dart';
import '../models/parent_daily_diary.dart';

class ParentDailyDiaryQuery {
  const ParentDailyDiaryQuery({
    this.period = 'today',
    this.date,
  });

  final String period;
  final String? date;

  ParentDailyDiaryQuery copyWith({
    String? period,
    String? date,
  }) {
    return ParentDailyDiaryQuery(
      period: period ?? this.period,
      date: date ?? this.date,
    );
  }
}

class ParentDailyDiaryService {
  ParentDailyDiaryService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<ParentDailyDiaryData> fetch(
    AuthSession session, {
    ParentDailyDiaryQuery query = const ParentDailyDiaryQuery(),
  }) async {
    final domain = session.school?.domain?.trim() ?? '';
    if (domain.isEmpty) {
      throw const ApiException('School domain is missing. Please sign in again.');
    }

    final studentId = session.selectedStudentId;
    if (studentId == null) {
      throw const ApiException('Select a student to view the daily diary.');
    }

    final json = await _client.get(
      ApiEndpoints.parentStudentDailyDiary,
      token: session.token,
      query: {
        'domain': domain,
        'student_id': '$studentId',
        'period': query.period,
        if (query.date != null && query.date!.isNotEmpty) 'date': query.date!,
      },
    );

    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Unexpected daily diary response.');
    }

    return ParentDailyDiaryData.fromJson(data);
  }
}
