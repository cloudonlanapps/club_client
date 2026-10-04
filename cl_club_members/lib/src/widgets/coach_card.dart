import 'package:cl_remote_store/cl_remote_store.dart'
    show clPublicMediaUrlProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show PublicProfile;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ThemedMarkdown;

import 'placeholder_avatar.dart';

/// A coach from the public staff list: photo, name, bio and achievements.
///
/// The public counterpart of `PublicProfileView`, for a page that lists every
/// coach. On a phone the photo sits above the text; on a wider screen it
/// fills the card's left side.
class CoachCard extends ConsumerWidget {
  const CoachCard({required this.coach, required this.isMobile, super.key});

  /// Width of the photo column on a wide screen.
  static const double desktopImageWidth = 300;

  /// Shortest the card is on a wide screen.
  static const double desktopMinHeight = 300;

  final PublicProfile coach;

  /// Whether to lay the card out for a phone.
  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);

    // Null whenever the coach has no publicly viewable avatar, which is also
    // what a profile with no avatar at all looks like from out here.
    final avatarUrl = ref.watch(clPublicMediaUrlProvider)(coach.avatar);
    final bio = coach.bio;
    final achievements = coach.achievements;

    final contentWidget = Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(coach.displayName, style: theme.textTheme.h3),
          const SizedBox(height: 24),
          if (bio != null && bio.isNotEmpty) ...[
            ThemedMarkdown(
              data: bio,
              selectable: false,
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 24),
          ],
          if (achievements != null && achievements.isNotEmpty)
            ThemedMarkdown(
              data: achievements,
              selectable: false,
              textAlign: TextAlign.justify,
            ),
        ],
      ),
    );

    if (isMobile) {
      // The column gives the photo no height of its own, so the placeholder
      // (which fills what it is given) is held square.
      const placeholder = AspectRatio(
        aspectRatio: 1,
        child: PlaceholderAvatar(),
      );
      return Card(
        margin: const EdgeInsets.only(bottom: 32),
        elevation: 4,
        shadowColor: theme.colorScheme.border.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.border),
        ),
        color: theme.colorScheme.card,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: avatarUrl != null
                    ? Image.network(
                        avatarUrl,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) =>
                            placeholder,
                      )
                    : placeholder,
              ),
            ),
            contentWidget,
          ],
        ),
      );
    }

    // Desktop: the photo is positioned to fill the left side.
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      constraints: const BoxConstraints(minHeight: desktopMinHeight),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            right: null,
            child: SizedBox(
              width: desktopImageWidth,
              child: avatarUrl != null
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) =>
                          const PlaceholderAvatar(),
                    )
                  : const PlaceholderAvatar(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: desktopImageWidth),
            child: contentWidget,
          ),
        ],
      ),
    );
  }
}
