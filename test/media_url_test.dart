import 'package:flutter_test/flutter_test.dart';
import 'package:lmssystem/core/media_url.dart';

void main() {
  test('builds tenancy asset url from a stored teacher photo path', () {
    expect(
      MediaUrl.resolve(
        'teachers/542532c4-90db-44bf-9770-85a7085497e2.jpg',
        schoolDomain: 'sls.localhost',
      ),
      'http://sls.localhost/tenancy/assets/teachers/542532c4-90db-44bf-9770-85a7085497e2.jpg',
    );
  });

  test('uses the login domain as the asset host', () {
    expect(
      MediaUrl.resolve(
        'teachers/sara.jpg',
        schoolDomain: 'sls.198.211.105.64',
      ),
      'http://sls.198.211.105.64/tenancy/assets/teachers/sara.jpg',
    );
  });

  test('normalizes stored tenancy and storage urls onto the login domain', () {
    expect(
      MediaUrl.resolve(
        'http://sls.localhost/tenancy/assets/teachers/sara.jpg',
        schoolDomain: 'sls.localhost',
      ),
      'http://sls.localhost/tenancy/assets/teachers/sara.jpg',
    );
    expect(
      MediaUrl.resolve(
        'http://localhost:8000/storage/teachers/sara.png',
        schoolDomain: 'sls.localhost',
      ),
      'http://sls.localhost/tenancy/assets/teachers/sara.png',
    );
  });

  test('leaves remote urls unchanged', () {
    expect(
      MediaUrl.resolve('https://cdn.example.com/sara.jpg', schoolDomain: 'sls.localhost'),
      'https://cdn.example.com/sara.jpg',
    );
  });
}
