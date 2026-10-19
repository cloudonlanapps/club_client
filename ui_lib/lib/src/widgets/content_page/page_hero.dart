import 'package:flutter/material.dart';

import '../../models/page_hero_data.dart';
import '../content_page_hero_section.dart';

/// A page's hero: its [PageHeroData] in [ContentPageHeroSection].
///
/// A page without an image of its own shows [fallbackImageUri] instead (a
/// site's default hero), so the badge, title and description never go
/// without a picture.
class PageHero extends StatelessWidget {
  const PageHero({
    required this.data,
    super.key,
    this.fallbackImageUri,
    this.topWidget,
    this.bottomWidget,
    this.useStampBadge = false,
    this.leftAlign = false,
    this.icon,
  });

  /// The page's hero copy and optional image.
  final PageHeroData data;

  /// Shown when [data] has no image of its own.
  final String? fallbackImageUri;

  /// Shown above the badge / title (e.g., info cards for programmes).
  final Widget? topWidget;

  /// Shown below the description (e.g., info cards for camps / one-off).
  final Widget? bottomWidget;

  /// Draws the badge as a stamp rather than an outline badge.
  final bool useStampBadge;

  /// Left-aligns the content instead of centring it (for programmes).
  final bool leftAlign;

  /// Shown instead of the badge (e.g., a map pin for a venue).
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ContentPageHeroSection(
      title: data.title,
      badge: data.badge,
      description: data.description,
      imageUri: data.imageUri,
      fallbackImageUri: fallbackImageUri,
      topWidget: topWidget,
      bottomWidget: bottomWidget,
      useStampBadge: useStampBadge,
      leftAlign: leftAlign,
      icon: icon,
      selectable: false,
    );
  }
}
