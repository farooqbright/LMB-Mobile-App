import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/auth_session.dart';
import '../models/login_credentials.dart';

class AuthService {
  AuthService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<AuthSession> login(LoginCredentials credentials) async {
    final json = await _client.post(
      ApiEndpoints.login,
      body: {
        'domain': credentials.schoolDomain,
        'username': credentials.username,
        'password': credentials.password,
      },
    );

    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Unexpected login response.');
    }

    try {
      return AuthSession.fromJson(data);
    } on FormatException catch (error) {
      throw ApiException(error.message);
    }
  }

  Future<void> changePassword({
    required AuthSession session,
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    final domain = session.school?.domain?.trim() ?? '';
    if (domain.isEmpty) {
      throw const ApiException('School domain is missing. Please sign in again.');
    }

    await _client.post(
      ApiEndpoints.changePassword,
      token: session.token,
      body: {
        'domain': domain,
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }
}
