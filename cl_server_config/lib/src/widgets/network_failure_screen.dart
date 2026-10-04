import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../providers/network_status.dart';

/// Screen displayed when network is unavailable or server is unreachable.
///
/// Shows a status icon, message, and retry button. An optional [footer]
/// widget can be provided for shell-specific messaging (e.g. a contact hint).
class NetworkFailureScreen extends ConsumerWidget {
  const NetworkFailureScreen({
    required this.status,
    super.key,
    this.footer,
  });

  final NetworkStatus status;

  /// Optional widget shown below the retry button.
  final Widget? footer;

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
                isOffline ? 'No Internet Connection' : 'Server Unavailable',
                style: theme.textTheme.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                isOffline
                    ? 'Please check your internet connection and try again.'
                    : 'Our servers are temporarily unavailable. '
                          'Please try again in a moment.',
                style: theme.textTheme.muted,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ShadButton(
                onPressed: () {
                  ref.read(networkStatusProvider.notifier).checkNow();
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.refreshCw, size: 16),
                    SizedBox(width: 8),
                    Text('Try Again'),
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
