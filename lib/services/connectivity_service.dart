import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  static final ConnectivityService instance = ConnectivityService();

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _online = true;

  bool get isOnline => _online;

  @visibleForTesting
  void debugSetOnline(bool online) {
    if (online == _online) return;
    _online = online;
    notifyListeners();
  }

  Future<void> start() async {
    try {
      _apply(await _connectivity.checkConnectivity());
      await _subscription?.cancel();
      _subscription = _connectivity.onConnectivityChanged.listen(_apply);
    } catch (_) {
      _online = true;
      notifyListeners();
    }
  }

  void _apply(List<ConnectivityResult> results) {
    final online = results.any((result) => result != ConnectivityResult.none);
    if (online == _online) return;
    _online = online;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
