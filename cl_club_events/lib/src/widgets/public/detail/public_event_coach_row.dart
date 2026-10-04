import 'package:club_sdk_2/club_sdk_2.dart' show PublicProfile;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ThemedMarkdown;

/// One coach of a public event: an icon, "Guest" when the server marks them
/// so, their name and bio.
class PublicEventCoachRow extends StatelessWidget {
  const PublicEventCoachRow({
    required this.profile,
    required this.themeColor,
    super.key,
  });

  /// The mark over a guest coach's name.
  static const String guestLabel = 'Guest';

  final PublicProfile profile;
  final Color themeColor;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final bio = profile.bio;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.user, size: 20, color: themeColor),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (profile.isGuest)
                  Text(
                    guestLabel,
                    style: theme.textTheme.muted.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                Text(
                  profile.displayName,
                  style: theme.textTheme.p.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (bio != null && bio.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  ThemedMarkdown(
                    data: bio,
                    selectable: false,
                    textStyle: theme.textTheme.muted,
                    textAlign: TextAlign.justify,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
