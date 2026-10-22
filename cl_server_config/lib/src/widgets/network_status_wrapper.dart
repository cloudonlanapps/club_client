import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/network_status.dart';
import 'network_failure_banner.dart';

/// Wrapper widget that monitors network status and shows a
/// [NetworkFailureBanner] over its child when the server is unreachable.
///
/// Place this widget around content that requires network connectivity.
/// The child stays mounted whatever the status, so a page keeps what was
/// typed, its focus and its scroll position through a dropped connection
/// (club_client#163); the banner sits over the top of the page while the
/// network is offline or the server is unavailable, and goes once it is
/// back.
///
/// An optional [footer] is forwarded to the banner for shell-specific
/// messaging.
class NetworkStatusWrapper extends ConsumerWidget {
  /// Creates a wrapper around [child].
  const NetworkStatusWrapper({
    required this.child,
    super.key,
    this.footer,
  });

  /// The page, kept mounted whatever the network status.
  final Widget child;

  /// Optional widget shown below the banner's message.
  final Widget? footer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(networkStatusProvider);

    // The child stays first in the list, so adding or removing the banner
    // never rebuilds it.
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        if (status != NetworkStatus.online)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: NetworkFailureBanner(status: status, footer: footer),
            ),
          ),
      ],
    );
  }
}
