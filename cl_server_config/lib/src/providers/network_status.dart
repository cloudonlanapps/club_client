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
///   fails.
/// - A data provider calls [NetworkStatusNotifier.markOnline] after a fetch
///   succeeds.
/// - The user taps "Try Again" on the network failure screen.
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

  final Ref ref;
  bool _isChecking = false;

  /// Force an immediate health check against the server.
  ///
  /// Call this when an API error is encountered. The result updates [state].
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

  /// Performs a health check via direct HTTP GET to the `/health` endpoint.
  Future<void> _checkHealth() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final baseUrl = ref.read(apiBaseUrlProvider);
      final healthUrl = _buildHealthUrl(baseUrl);

      final response = await http
          .get(Uri.parse(healthUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        if (state != NetworkStatus.online) {
          state = NetworkStatus.online;
        }
      } else {
        if (kDebugMode) {
          print(
            '[NetworkStatus] Health check failed: '
            'server returned ${response.statusCode}',
          );
        }
        if (state != NetworkStatus.serverUnavailable) {
          state = NetworkStatus.serverUnavailable;
        }
      }
    } on Object catch (e) {
      if (kDebugMode) {
        print('[NetworkStatus] Health check error: $e');
      }

      final newState = _isNetworkError(e)
          ? NetworkStatus.offline
          : NetworkStatus.serverUnavailable;

      if (state != newState) {
        state = newState;
      }
    } finally {
      _isChecking = false;
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
