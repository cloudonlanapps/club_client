import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ClubTextTheme;

import 'public_events_section_reveal.dart';

/// A landing event section's header: an outlined badge (tapping it calls
/// [onBadgeTap]), the title and a short description.
class PublicEventsSectionHeader extends StatelessWidget {
  const PublicEventsSectionHeader({
    required this.badge,
    required this.title,
    required this.description,
    required this.isMobile,
    this.visible = true,
    this.onBadgeTap,
    super.key,
  });

  final String badge;
  final String title;
  final String description;
  final bool isMobile;

  /// Whether the header has been revealed.
  final bool visible;

  /// Called when the badge is tapped.
  final VoidCallback? onBadgeTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Column(
      children: [
        PublicEventsSectionReveal(
          visible: visible,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onBadgeTap,
              child: ShadBadge.outline(
                child: Text(badge, style: theme.textTheme.badgeText),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        PublicEventsSectionReveal(
          visible: visible,
          child: Text(
            title,
            style: theme.textTheme
                .heroTitle(isMobile: isMobile)
                .copyWith(height: 1.2),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        PublicEventsSectionReveal(
          visible: visible,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Text(
              description,
              style: theme.textTheme
                  .sectionDescription(isMobile: isMobile)
                  .copyWith(height: 1.6),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
