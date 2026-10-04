import 'package:cl_remote_store/cl_remote_store.dart'
    show clMemberCreditTotalProvider, clUsersMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The top of the credit view (club_core#101): the member, their status
/// when staff are looking (credit can be recorded for a member of any
/// status), and their usable credit — the same number as the chip that
/// opened it. Admins get Add credit here.
class CreditHeader extends ConsumerWidget {
  const CreditHeader({
    required this.currentUser,
    required this.username,
    this.onAddCredit,
    super.key,
  });

  final UserPrivate currentUser;
  final String username;

  /// Opens Add credit; null hides it (anyone but an admin).
  final VoidCallback? onAddCredit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final isSelf = currentUser.username == username;
    final member = isSelf
        ? null
        : ref.watch(clUsersMasterProvider).valueOrNull?[username];
    final name = isSelf ? currentUser.displayName : member?.displayName;
    final total = ref.watch(clMemberCreditTotalProvider(username));

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name ?? username, style: theme.textTheme.large),
              Text(
                member == null ? username : '$username · ${member.status.name}',
                style: theme.textTheme.muted,
              ),
            ],
          ),
        ),
        Semantics(
          container: true,
          label: 'Credit ${total ?? ''}',
          excludeSemantics: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              const Icon(LucideIcons.coins, size: 20),
              Text(total?.toString() ?? '', style: theme.textTheme.h3),
            ],
          ),
        ),
        if (onAddCredit != null) ...[
          const SizedBox(width: 12),
          ShadButton.outline(
            size: ShadButtonSize.sm,
            onPressed: onAddCredit,
            leading: const Icon(LucideIcons.plus, size: 14),
            child: const Text('Add credit'),
          ),
        ],
      ],
    );
  }
}
