import 'constants/api_config.dart';

/// Builds `http://{loginDomain}/tenancy/assets/{path}` from a stored file path.
class MediaUrl {
  MediaUrl._();

  static String? resolve(String? url, {String? schoolDomain}) {
    final raw = url?.trim();
    if (raw == null || raw.isEmpty) return null;

    final domain = _host(schoolDomain);
    final path = _relativePath(raw);
    if (path == null || path.isEmpty) return raw;
    if (domain == null || domain.isEmpty) return raw;

    final scheme = Uri.tryParse(ApiConfig.baseUrl)?.scheme ?? 'http';
    return '$scheme://$domain/tenancy/assets/$path';
  }

  static String? _host(String? schoolDomain) {
    final value = schoolDomain?.trim();
    if (value == null || value.isEmpty) return null;
    if (value.contains('://')) {
      return Uri.tryParse(value)?.host ?? value;
    }
    return value.split('/').first;
  }

  static String? _relativePath(String raw) {
    var value = raw.trim();
    final uri = Uri.tryParse(value);

    if (uri != null && uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
      var path = uri.path;
      if (path.startsWith('/')) path = path.substring(1);

      final host = uri.host.toLowerCase();
      final isLocal = host == 'localhost' || host == '127.0.0.1' || host.endsWith('.localhost');
      final isTenantPath = path.startsWith('tenancy/assets/') || path.startsWith('storage/');

      if (!isLocal && !isTenantPath) return null;
      value = path;
    } else {
      value = value.replaceFirst(RegExp(r'^/+'), '');
    }

    if (value.startsWith('tenancy/assets/')) {
      value = value.substring('tenancy/assets/'.length);
    } else if (value.startsWith('storage/')) {
      value = value.substring('storage/'.length);
    }

    return value.isEmpty ? null : value;
  }
}
