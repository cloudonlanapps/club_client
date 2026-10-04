import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'stamp_badge.dart';

/// The mark above a `ContentPageHeroSection`'s title: [icon] when given,
/// otherwise [badge] as a [StampBadge] or an outline badge.
class ContentPageHeroMark extends StatelessWidget {
  const ContentPageHeroMark({
    required this.isMobile,
    super.key,
    this.icon,
    this.badge,
    this.useStampBadge = false,
  });

  /// Shown instead of [badge] when set.
  final IconData? icon;

  /// Badge text, e.g. "BATCH 1".
  final String? badge;

  /// Draws [badge] as a [StampBadge] rather than an outline badge.
  final bool useStampBadge;

  /// Sizes the icon for a narrow screen.
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final iconData = icon;
    final text = badge;
    final Widget mark;
    if (iconData != null) {
      mark = Icon(
        iconData,
        size: isMobile ? 48 : 64,
        color: ShadTheme.of(context).colorScheme.foreground,
      );
    } else if (text != null) {
      mark = useStampBadge
          ? StampBadge(text: text)
          : ShadBadge.outline(child: Text(text));
    } else {
      return const SizedBox.shrink();
    }
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: mark);
  }
}
