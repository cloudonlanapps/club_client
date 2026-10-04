import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../providers/token_expiry.dart';

/// Displays remaining session time as `hh:mm` with a clock icon.
///
/// Watches [tokenExpiryProvider] and re-renders every minute via a periodic
/// timer. Shows nothing when no session is active, and an "Expired" label
/// with destructive styling when the session has expired.
class SessionCountdown extends ConsumerStatefulWidget {
  const SessionCountdown({super.key});

  @override
  ConsumerState<SessionCountdown> createState() => SessionCountdownState();
}

class SessionCountdownState extends ConsumerState<SessionCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final expiresAt = ref.watch(tokenExpiryProvider);
    if (expiresAt == null) return const SizedBox.shrink();

    final theme = ShadTheme.of(context);
    final remaining = expiresAt.difference(DateTime.now().toUtc());

    if (remaining <= Duration.zero) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.clockAlert,
            size: 14,
            color: theme.colorScheme.destructive,
          ),
          const SizedBox(width: 4),
          Text(
            'Expired',
            style: theme.textTheme.muted.copyWith(
              fontSize: 12,
              color: theme.colorScheme.destructive,
            ),
          ),
        ],
      );
    }

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final timeText =
        '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          LucideIcons.clock,
          size: 14,
          color: theme.colorScheme.mutedForeground,
        ),
        const SizedBox(width: 4),
        Text(
          timeText,
          style: theme.textTheme.muted.copyWith(fontSize: 12),
        ),
      ],
    );
  }
}
