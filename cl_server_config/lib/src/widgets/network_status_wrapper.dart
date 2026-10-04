import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/network_status.dart';
import 'network_failure_screen.dart';

/// Wrapper widget that monitors network status and shows a failure screen
/// when the server is unreachable.
///
/// Place this widget around content that requires network connectivity.
/// When the network is offline or the server is unavailable, it displays
/// a [NetworkFailureScreen] instead of the child content.
///
/// An optional [footer] is forwarded to [NetworkFailureScreen] for
/// shell-specific messaging.
class NetworkStatusWrapper extends ConsumerWidget {
  const NetworkStatusWrapper({
    required this.child,
    super.key,
    this.footer,
  });

  final Widget child;

  /// Optional widget shown below the retry button on the failure screen.
  final Widget? footer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(networkStatusProvider);

    switch (status) {
      case NetworkStatus.offline:
      case NetworkStatus.serverUnavailable:
        return NetworkFailureScreen(status: status, footer: footer);
      case NetworkStatus.online:
        return child;
    }
  }
}
