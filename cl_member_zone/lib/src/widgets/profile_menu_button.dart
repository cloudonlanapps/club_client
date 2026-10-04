import 'package:cl_member_auth/cl_member_auth.dart'
    show imageAuthHeadersProvider;
import 'package:cl_remote_store/cl_remote_store.dart' show avatarImageProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show AvatarCircleVariant, CredentialedNetworkImage;

class ProfileMenuButton extends ConsumerStatefulWidget {
  const ProfileMenuButton({
    required this.username,
    required this.displayName,
    required this.onProfile,
    required this.onSignOut,
    super.key,
  });

  final String username;
  final String displayName;
  final VoidCallback onProfile;
  final VoidCallback onSignOut;

  @override
  ConsumerState<ProfileMenuButton> createState() => ProfileMenuButtonState();
}

class ProfileMenuButtonState extends ConsumerState<ProfileMenuButton> {
  final ShadPopoverController controller = ShadPopoverController();

  static const double _size = 32;

  /// The signed-in user's avatar, or initials when no avatar is set (or the
  /// image is still resolving / failed to load).
  Widget _anchorAvatar(ShadThemeData theme) {
    final avatarUrl = ref.watch(avatarImageProvider(widget.username)).value;
    final initials = AvatarCircleVariant(
      name: widget.displayName,
      size: _size,
      color: theme.colorScheme.primary,
    );
    if (avatarUrl == null) return initials;
    final headers = ref.watch(imageAuthHeadersProvider).value ?? const {};
    // Match AvatarCircleVariant's rounded-square shape (radius = size * 0.25),
    // not a full circle, so the image and the initials fallback look identical.
    return ClipRRect(
      borderRadius: BorderRadius.circular(_size * 0.25),
      child: SizedBox.square(
        dimension: _size,
        child: CredentialedNetworkImage(
          imageUrl: avatarUrl,
          httpHeaders: headers,
          fit: BoxFit.cover,
          errorBuilder: (_) => initials,
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadPopover(
      controller: controller,
      popover: (context) => SizedBox(
        width: 180,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ShadButton.ghost(
              onPressed: () {
                controller.hide();
                widget.onProfile();
              },
              leading: const Icon(LucideIcons.user, size: 16),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text('Profile'),
              ),
            ),
            const SizedBox(height: 4),
            ShadButton.ghost(
              onPressed: () {
                controller.hide();
                widget.onSignOut();
              },
              leading: Icon(
                Icons.logout,
                size: 16,
                color: theme.colorScheme.destructive,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sign out',
                  style: TextStyle(color: theme.colorScheme.destructive),
                ),
              ),
            ),
          ],
        ),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: controller.toggle,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: _anchorAvatar(theme),
        ),
      ),
    );
  }
}
