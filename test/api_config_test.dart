import 'package:flutter_test/flutter_test.dart';
import 'package:lmssystem/core/constants/api_config.dart';
import 'package:lmssystem/models/login_credentials.dart';

void main() {
  test('subdomain uses the root domain default from ApiConfig', () {
    expect(
      ApiConfig.schoolDomain(hostType: SchoolHostType.subdomain, host: 'sls'),
      'sls.localhost',
    );
  });

  test('domain keeps the full host', () {
    expect(
      ApiConfig.schoolDomain(
        hostType: SchoolHostType.domain,
        host: 'sls.198.211.105.64.nip.io',
      ),
      'sls.198.211.105.64.nip.io',
    );
  });
}
