import 'package:cl_club_credits/cl_club_credits.dart' show CreditChip;
import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart' show creditSystemProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show UserInfo, UserStatus;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The member's name followed by their credit, 🪙 N, on the profile card
/// (club_core#102). Present only where the credit system is on; the chip
/// opens the member's credit view.
///
/// A member who is not yet active (onboarding's profile page,
/// club_client#340) has no credit of their own to read: the server answers
/// a member's own credit to an active member only, so on their own card the
/// line is left out.
class ProfileCreditLine extends ConsumerWidget {
  const ProfileCreditLine({required this.user, super.key});

  final UserInfo user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(creditSystemProvider) != true) return const SizedBox.shrink();
    final viewer = ref.watch(authStateProvider).valueOrNull;
    final ownBeforeApproval =
        viewer?.username == user.username && user.status != UserStatus.active;
    if (ownBeforeApproval) return const SizedBox.shrink();
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        spacing: 12,
        children: [
          Flexible(
            child: Text(
              user.displayName,
              style: theme.textTheme.h4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          CreditChip(username: user.username),
        ],
      ),
    );
  }
}
