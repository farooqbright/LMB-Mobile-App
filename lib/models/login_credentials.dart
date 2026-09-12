enum SchoolHostType { subdomain, domain }

class LoginCredentials {
  const LoginCredentials({
    required this.hostType,
    required this.host,
    required this.schoolDomain,
    required this.username,
    required this.password,
    this.rememberMe = false,
  });

  final SchoolHostType hostType;
  final String host;

  /// Full tenant host sent to the API as `domain` (e.g. `sls.localhost`).
  final String schoolDomain;

  final String username;
  final String password;
  final bool rememberMe;
}
