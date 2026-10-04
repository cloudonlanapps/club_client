import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

/// Avatar area that fills its parent, showing the user's image or
/// centered initials on a coloured background.
///
/// Reads the avatar URL via `avatarImageProvider(user.username)` (v2 media
/// tagged `user_avatar`) and renders through [CredentialedNetworkImage]
/// with bearer headers from `imageAuthHeadersProvider`. Falls back to
/// initials when the user has no avatar or the URL is still resolving.
///
/// Set [dimmed] to true for inactive users (blocked, left) to use muted
/// colours.
class UserAvatar extends ConsumerWidget {
  const UserAvatar({
    required this.user,
    this.dimmed = false,
    this.fontSize = 56,
    super.key,
  });

  final UserInfo user;
  final bool dimmed;

  /// Font size for the initials text. Defaults to 56 for large profile
  /// cards; callers can pass a smaller value for list cards.
  final double fontSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final initials = _initials(user);
    final bgColor = dimmed ? theme.colorScheme.muted : theme.colorScheme.muted;
    final fgColor = dimmed
        ? theme.colorScheme.mutedForeground.withValues(alpha: 0.5)
        : theme.colorScheme.mutedForeground;

    final avatarUrl = ref.watch(avatarImageProvider(user.username)).value;
    final headers = ref.watch(imageAuthHeadersProvider).value ?? const {};
    if (avatarUrl == null) {
      return _placeholder(initials, bgColor, fgColor);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return ColoredBox(
          color: bgColor,
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : constraints.maxWidth,
            child: CredentialedNetworkImage(
              imageUrl: avatarUrl,
              httpHeaders: headers,
              // BoxFit.contain so the user's full photo is visible inside
              // the avatar slot. The avatar background colour fills any
              // letterboxed area; never crop a profile picture.
              fit: BoxFit.contain,
              errorBuilder: (_) => _placeholder(initials, bgColor, fgColor),
            ),
          ),
        );
      },
    );
  }

  Widget _placeholder(String initials, Color bg, Color fg) {
    return ColoredBox(
      color: bg,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: fg,
          ),
        ),
      ),
    );
  }

  static String _initials(UserInfo user) {
    final first = (user.firstName ?? '').trim();
    final last = (user.lastName ?? '').trim();
    if (first.isNotEmpty && last.isNotEmpty) {
      return '${first[0]}${last[0]}'.toUpperCase();
    }
    if (first.isNotEmpty) return first[0].toUpperCase();
    if (user.displayName.isNotEmpty) return user.displayName[0].toUpperCase();
    return '?';
  }
}
