import 'package:cl_club_members/src/providers/pending_users.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Banner shown above the admin user list when there are pending
/// registrations awaiting approval.
///
/// Hidden entirely when the pending count is 0. Tapping "Act Now" invokes
/// [onActNow], which the host wires to the admin review surface.
class PendingApprovalsBanner extends ConsumerWidget {
  const PendingApprovalsBanner({required this.onActNow, super.key});

  final VoidCallback onActNow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(pendingUsersCountProvider);
    if (count == 0) return const SizedBox.shrink();

    final theme = ShadTheme.of(context);
    final plural = count == 1 ? 'registration' : 'registrations';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: ShadCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              LucideIcons.userCheck,
              size: 18,
              color: theme.colorScheme.mutedForeground,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'You have $count $plural waiting for approval.',
                style: theme.textTheme.small,
              ),
            ),
            const SizedBox(width: 12),
            ShadButton.outline(
              onPressed: onActNow,
              child: const Text('Act Now'),
            ),
          ],
        ),
      ),
    );
  }
}
