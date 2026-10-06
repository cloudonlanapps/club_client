import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../utils/member_write_messages.dart';

/// "Allow others to see my photo" tick for a member's CURRENT profile photo
/// (club_client#35).
///
/// Ticking makes the photo public, unticking makes it private again, both
/// through `avatarMutationProvider(username).setVisibility(...)` and without
/// a new upload. This is how a photo an admin uploaded becomes public.
///
/// Shown on the member's own profile only. Renders nothing while the member
/// has no photo, or until the photo's visibility is known.
class AvatarVisibilityToggle extends ConsumerWidget {
  /// Creates the tick for [username]'s current photo.
  const AvatarVisibilityToggle({required this.username, super.key});

  /// The signed-in member, whose photo this is.
  final String username;

  /// Asks the notifier to change the visibility; a refusal shows as a toast.
  Future<void> change(
    BuildContext context,
    WidgetRef ref, {
    required bool allowOthersToSee,
  }) async {
    final toaster = ShadToaster.of(context);
    try {
      await ref
          .read(avatarMutationProvider(username).notifier)
          .setVisibility(allowOthersToSee: allowOthersToSee);
    } on Object catch (e) {
      toaster.show(
        ShadToast.destructive(
          description: Text(
            writeFailureMessage(
              e,
              fallback: MemberWriteMessages.photoVisibilityFailed,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPhoto = ref.watch(avatarImageProvider(username)).value != null;
    if (!hasPhoto) return const SizedBox.shrink();
    final isPublic = ref.watch(avatarVisibilityProvider(username)).value;
    if (isPublic == null) return const SizedBox.shrink();
    final busy = ref.watch(avatarMutationProvider(username)).isLoading;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: ShadCheckbox(
        value: isPublic,
        enabled: !busy,
        onChanged: (v) => change(context, ref, allowOthersToSee: v),
        label: Text(
          MemberWriteMessages.allowOthersToSeePhoto,
          style: ShadTheme.of(context).textTheme.small,
        ),
      ),
    );
  }
}
