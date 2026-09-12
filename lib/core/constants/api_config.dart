import '../../models/login_credentials.dart';

/// Server address and tenant-host rules.
///
/// Override at run time without editing this file:
/// `flutter run --dart-define=API_BASE_URL=https://api.example.com/api --dart-define=SCHOOL_ROOT_DOMAIN=example.com`
class ApiConfig {
  ApiConfig._();

  /// Central LMS API root. Login hits this host; school is chosen via `domain` in the body.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api',
  );

  /// Appended when the user picks Subdomain (e.g. `sls` → `sls.localhost`).
  static const String rootDomain = String.fromEnvironment(
    'SCHOOL_ROOT_DOMAIN',
    defaultValue: 'localhost',
  );

  static const Duration timeout = Duration(seconds: 20);

  static Uri uri(String endpoint) {
    final root = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri.parse('$root$path');
  }

  /// Value posted as `domain` so Laravel can initialize the tenant.
  static String schoolDomain({
    required SchoolHostType hostType,
    required String host,
  }) {
    final value = host.trim().toLowerCase();
    if (hostType == SchoolHostType.subdomain) {
      return '$value.$rootDomain';
    }
    return value;
  }
}
