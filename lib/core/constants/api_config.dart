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
    //defaultValue: 'http://198.211.105.64.nip.io/api',
    defaultValue: 'http://localhost:8000/api',
  );

  /// Appended when the user picks Subdomain (e.g. `sls` → `sls.198.211.105.64.nip.io`).
  static const String rootDomain = String.fromEnvironment(
    'SCHOOL_ROOT_DOMAIN',
    // defaultValue: '198.211.105.64.nip.io',
    defaultValue: 'localhost/8000',
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
    var value = host.trim().toLowerCase();
    value = value.replaceFirst(RegExp(r'^https?://'), '');
    value = value.split('/').first;
    if (hostType == SchoolHostType.subdomain) {
      final root = rootDomain
          .trim()
          .toLowerCase()
          .replaceFirst(RegExp(r'^https?://'), '')
          .replaceFirst(RegExp(r'^\.+'), '')
          .split('/')
          .first;
      return '$value.$root';
    }
    return value;
  }
}
