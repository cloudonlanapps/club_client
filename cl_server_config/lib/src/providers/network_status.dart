import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'config.dart';

/// Network connectivity and server availability status.
enum NetworkStatus {
  /// Server is reachable and responding.
  online,

  /// Device appears to be offline (network unreachable).
  offline,

  /// Network available but server is not responding.
  serverUnavailable,
}

/// Provider for monitoring network and server status.
///
/// Uses a **reactive** approach — no background polling. Status starts as
/// [NetworkStatus.online] and only changes when:
/// - A data provider calls [NetworkStatusNotifier.checkNow] after a fetch
///   fails, and the health check fails twice in a row (one confirming check,
///   not polling).
/// - A data provider calls [NetworkStatusNotifier.markOnline] after a fetch
///   succeeds.
/// - The user taps "Try Again" on the network failure banner or screen.
final networkStatusProvider =
    StateNotifierProvider<NetworkStatusNotifier, NetworkStatus>((ref) {
      return NetworkStatusNotifier(ref);
    });

/// Notifier that tracks network connectivity and server availability.
///
/// Does **not** poll. Call [checkNow] when an API request fails, and
/// [markOnline] when one succeeds after a failure.
class NetworkStatusNotifier extends StateNotifier<NetworkStatus> {
  NetworkStatusNotifier(this.ref) : super(NetworkStatus.online);

  /// How long one health check may take before it counts as failed.
  static const Duration healthTimeout = Duration(seconds: 5);

  /// How long after a first failed health check the confirming one runs.
  static const Duration confirmDelay = Duration(seconds: 1);

  final Ref ref;
  bool _isChecking = false;
  Timer? _confirmTimer;

  /// Force an immediate health check against the server.
  ///
  /// Call this when an API error is encountered. The result updates [state];
  /// while online, only after a second failed check (club_client#163).
  void checkNow() {
    unawaited(_checkHealth());
  }

  /// Mark the server as online.
  ///
  /// Call this when an API request succeeds and the current state is not
  /// [NetworkStatus.online], to recover from a previous failure.
  void markOnline() {
    if (state != NetworkStatus.online) {
      state = NetworkStatus.online;
    }
  }

  /// Runs the health check behind [checkNow].
  ///
  /// While the status is [NetworkStatus.online], one failed check is not
  /// enough: on a patchy connection a single request fails or stalls in
  /// ordinary use. After [confirmDelay] the check runs once more, and only
  /// a second failure changes the status (club_client#163). Once the status
  /// is a failure, each check sets it directly.
  Future<void> _checkHealth() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      var result = await _probe();
      if (!mounted) return;
      if (result != NetworkStatus.online && state == NetworkStatus.online) {
        await _waitToConfirm();
        result = await _probe();
        // The provider may have been disposed while the request was in
        // flight.
        if (!mounted) return;
      }
      if (state != result) state = result;
    } finally {
      _isChecking = false;
    }
  }

  /// Completes after [confirmDelay]. Disposing the notifier cancels the
  /// wait, and the check it holds never resumes.
  Future<void> _waitToConfirm() {
    final waited = Completer<void>();
    _confirmTimer = Timer(confirmDelay, waited.complete);
    return waited.future;
  }

  @override
  void dispose() {
    _confirmTimer?.cancel();
    super.dispose();
  }

  /// Asks the server's `/health` endpoint once and returns the status its
  /// answer means.
  Future<NetworkStatus> _probe() async {
    try {
      final baseUrl = ref.read(apiBaseUrlProvider);
      final healthUrl = _buildHealthUrl(baseUrl);

      final response = await http
          .get(Uri.parse(healthUrl))
          .timeout(healthTimeout);

      if (response.statusCode == HttpStatus.ok) return NetworkStatus.online;
      if (kDebugMode) {
        print(
          '[NetworkStatus] Health check failed: '
          'server returned ${response.statusCode}',
        );
      }
      return NetworkStatus.serverUnavailable;
    } on Object catch (e) {
      if (kDebugMode) {
        print('[NetworkStatus] Health check error: $e');
      }
      return _isNetworkError(e)
          ? NetworkStatus.offline
          : NetworkStatus.serverUnavailable;
    }
  }

  /// Determines if an error indicates network unavailability.
  ///
  /// All [SocketException]s are treated as network errors **except**
  /// "connection refused", which means the network works but the server
  /// port is not listening.
  bool _isNetworkError(Object error) {
    if (error is SocketException) {
      final message = error.message.toLowerCase();
      if (message.contains('connection refused')) return false;
      return true;
    }
    return false;
  }

  /// Builds the health endpoint URL from the API base URL.
  ///
  /// Strips the `/v1` suffix (if present) and appends `/health`.
  /// Example: `https://api.example.com/v1` → `https://api.example.com/health`
  String _buildHealthUrl(String baseUrl) {
    final uri = Uri.parse(baseUrl);
    final segments = uri.pathSegments.toList();
    if (segments.isNotEmpty && segments.last == 'v1') {
      segments.removeLast();
    }
    segments.add('health');
    return uri.replace(pathSegments: segments).toString();
  }
}
