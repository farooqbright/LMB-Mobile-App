enum SchoolHostType { subdomain, domain }

class LoginCredentials {
  const LoginCredentials({
    required this.hostType,
    required this.host,
    required this.username,
    required this.password,
    this.rememberMe = false,
  });

  final SchoolHostType hostType;
  final String host;
  final String username;
  final String password;
  final bool rememberMe;
}
