import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lmssystem/services/connectivity_service.dart';

void main() {
  test('empty connectivity results keep the current online state', () {
    expect(
      ConnectivityService.isOnlineFrom(const [], current: true),
      isTrue,
    );
    expect(
      ConnectivityService.isOnlineFrom(const [], current: false),
      isFalse,
    );
  });

  test('wifi or mobile is treated as online', () {
    expect(
      ConnectivityService.isOnlineFrom(
        const [ConnectivityResult.wifi],
        current: false,
      ),
      isTrue,
    );
    expect(
      ConnectivityService.isOnlineFrom(
        const [ConnectivityResult.none, ConnectivityResult.mobile],
        current: false,
      ),
      isTrue,
    );
  });

  test('only none is treated as offline', () {
    expect(
      ConnectivityService.isOnlineFrom(
        const [ConnectivityResult.none],
        current: true,
      ),
      isFalse,
    );
  });
}
