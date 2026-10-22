import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/network_failure_copy.dart';
import '../providers/network_status.dart';
import 'network_failure_banner.dart';

/// Screen displayed when network is unavailable or server is unreachable,
/// for a view that has nothing of its own to show until the server answers
/// (the login view's session restore). A mounted page shows a
/// [NetworkFailureBanner] over it instead, through `NetworkStatusWrapper`
/// (club_client#163).
///
/// Shows a status icon, message, and retry button. Try Again asks the
/// network monitor to check the server and then runs [onRetry], for a
/// screen whose own request failed while the server still answers its
/// health check (club_client#257). An optional [footer] widget can be
/// provided for shell-specific messaging (e.g. a contact hint).
class NetworkFailureScreen extends ConsumerWidget {
  const NetworkFailureScreen({
    required this.status,
    super.key,
    this.footer,
    this.onRetry,
  });

  final NetworkStatus status;

  /// Optional widget shown below the retry button.
  final Widget? footer;

  /// Runs when Try Again is tapped, after the network check starts.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final isOffline = status == NetworkStatus.offline;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.destructive.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOffline ? LucideIcons.wifiOff : LucideIcons.serverOff,
                  size: 40,
                  color: theme.colorScheme.destructive,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                NetworkFailureCopy.title(status),
                style: theme.textTheme.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                NetworkFailureCopy.message(status),
                style: theme.textTheme.muted,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ShadButton(
                onPressed: () {
                  ref.read(networkStatusProvider.notifier).checkNow();
                  onRetry?.call();
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.refreshCw, size: 16),
                    SizedBox(width: 8),
                    Text(NetworkFailureCopy.retryLabel),
                  ],
                ),
              ),
              if (footer != null) ...[
                const SizedBox(height: 24),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
