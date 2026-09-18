enum SchoolHostType { subdomain, domain }

class LoginCredentials {
  const LoginCredentials({
    required this.hostType,
    required this.host,
    required this.schoolDomain,
    required this.username,
    required this.password,
  });

  final SchoolHostType hostType;
  final String host;

  /// Full tenant host sent to the API as `domain` (e.g. `sls.198.211.105.64.nip.io`).
  final String schoolDomain;

  final String username;
  final String password;
}
