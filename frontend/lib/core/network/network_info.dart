import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Provider that exposes a [NetworkInfo] instance.
final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfoImpl(Connectivity());
});

/// Abstraction for checking network connectivity.
abstract class NetworkInfo {
  /// Returns [true] if the device currently has an active internet connection.
  Future<bool> get isConnected;

  /// Stream of connectivity changes.
  Stream<List<ConnectivityResult>> get onConnectivityChanged;
}

/// Concrete implementation backed by [connectivity_plus].
class NetworkInfoImpl implements NetworkInfo {
  const NetworkInfoImpl(this._connectivity);

  final Connectivity _connectivity;

  @override
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return _hasConnection(results);
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);
  }
}

// ---------------------------------------------------------------------------
// Connectivity state notifier (useful for reactive UI)
// ---------------------------------------------------------------------------

/// Riverpod [AsyncNotifier] that tracks real-time connectivity state.
///
/// Usage in a widget:
/// ```dart
/// final isOnline = ref.watch(connectivityNotifierProvider).valueOrNull ?? true;
/// ```
final connectivityNotifierProvider =
    AsyncNotifierProvider<ConnectivityNotifier, bool>(() {
  return ConnectivityNotifier();
});

class ConnectivityNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final networkInfo = ref.watch(networkInfoProvider);

    // Listen to changes and rebuild state
    ref.onDispose(
      networkInfo.onConnectivityChanged.listen((results) {
        state = AsyncData(NetworkInfoImpl._hasConnection(results));
      }).cancel,
    );

    return networkInfo.isConnected;
  }
}
