import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Compact, color-coded badge for a [UserStatus].
class UserStatusChip extends StatelessWidget {
  const UserStatusChip({required this.status, super.key});

  final UserStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final (label, bg, fg) = switch (status) {
      UserStatus.active => (
        'Active',
        theme.colorScheme.primary.withValues(alpha: 0.15),
        theme.colorScheme.primary,
      ),
      UserStatus.pending => (
        'Pending',
        Colors.amber.withValues(alpha: 0.2),
        Colors.amber.shade900,
      ),
      UserStatus.blocked => (
        'Blocked',
        theme.colorScheme.destructive.withValues(alpha: 0.15),
        theme.colorScheme.destructive,
      ),
      UserStatus.left => (
        'Left',
        theme.colorScheme.muted,
        theme.colorScheme.mutedForeground,
      ),
      // Defensive: `registered` users are filtered out of admin lists in
      // `clUsersMasterProvider`, but a per-user lookup can still surface
      // one. Render a muted "Onboarding" chip, distinct from amber `pending`.
      UserStatus.registered => (
        'Onboarding',
        theme.colorScheme.muted,
        theme.colorScheme.mutedForeground,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.small.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
