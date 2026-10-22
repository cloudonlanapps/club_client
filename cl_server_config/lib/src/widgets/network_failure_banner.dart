import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/network_failure_copy.dart';
import '../providers/network_status.dart';

/// A banner that says the network or the server cannot be reached, shown
/// over a page that stays mounted underneath (club_client#163).
///
/// Try Again asks the network monitor to check the server. The banner takes
/// no focus of its own, so an open editor under it keeps the keyboard. An
/// optional [footer] is shown below the message.
class NetworkFailureBanner extends ConsumerWidget {
  /// Creates the banner for a failed [status].
  const NetworkFailureBanner({required this.status, super.key, this.footer});

  /// The failure the banner reports: [NetworkStatus.offline] or
  /// [NetworkStatus.serverUnavailable].
  final NetworkStatus status;

  /// Optional widget shown below the message.
  final Widget? footer;

  /// The space between the banner and the page's edges.
  static const EdgeInsets margin = EdgeInsets.all(12);

  /// The widest the banner grows on a wide screen.
  static const double maxWidth = 640;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final isOffline = status == NetworkStatus.offline;

    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: margin,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxWidth),
            child: ShadAlert.destructive(
              decoration: ShadDecoration(
                color: theme.colorScheme.background,
              ),
              icon: Icon(
                isOffline ? LucideIcons.wifiOff : LucideIcons.serverOff,
              ),
              title: Text(NetworkFailureCopy.title(status)),
              description: Text(NetworkFailureCopy.message(status)),
              trailing: ShadButton.outline(
                size: ShadButtonSize.sm,
                onPressed: ref.read(networkStatusProvider.notifier).checkNow,
                leading: const Icon(LucideIcons.refreshCw),
                child: const Text(NetworkFailureCopy.retryLabel),
              ),
              bottom: footer,
            ),
          ),
        ),
      ),
    );
  }
}
