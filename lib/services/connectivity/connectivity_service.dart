import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Monitors network connectivity using connectivity_plus (Android ConnectivityManager).
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _current = false;

  bool get isOnline => _current;

  Stream<bool> get onConnectivityChanged => _controller.stream;

  Future<void> start() async {
    final initial = await _connectivity.checkConnectivity();
    _update(_isConnected(initial));
    _sub = _connectivity.onConnectivityChanged.listen((results) {
      _update(_isConnected(results));
    });
  }

  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);
  }

  void _update(bool value) {
    if (_current == value) {
      // Still emit? Only on change to avoid redundant sync triggers.
      return;
    }
    _current = value;
    _controller.add(value);
  }

  /// Force re-evaluate and emit current state.
  Future<bool> check() async {
    final results = await _connectivity.checkConnectivity();
    final value = _isConnected(results);
    if (value != _current) {
      _current = value;
      _controller.add(value);
    }
    return value;
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
