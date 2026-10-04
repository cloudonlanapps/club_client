import 'package:cl_remote_store/cl_remote_store.dart'
    show SiteMediaSlot, clPublicSiteMediaProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_lib/ui_lib.dart' show ContentPageHeroSection;

import '../extensions/site_media_slot_bundled_asset.dart';
import '../page_content/page_common.dart';

/// A page's hero: its [PageHeroData] in ui_lib's [ContentPageHeroSection].
///
/// A page without an image of its own — every content page, and a venue
/// without a photo — shows the site's default hero slot instead, so the
/// badge, title and description never go with the picture.
class PageHero extends ConsumerWidget {
  const PageHero({
    required this.data,
    super.key,
    this.topWidget,
    this.bottomWidget,
    this.useStampBadge = false,
    this.leftAlign = false,
    this.icon,
  });

  /// The page's hero copy and optional image.
  final PageHeroData data;

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
  Widget build(BuildContext context, WidgetRef ref) {
    return ContentPageHeroSection(
      title: data.title,
      badge: data.badge,
      description: data.description,
      imageUri: data.imageUri,
      fallbackImageUri:
          ref
              .watch(clPublicSiteMediaProvider(SiteMediaSlot.pageHeroDefault))
              ?.uri ??
          SiteMediaSlot.pageHeroDefault.bundledAsset,
      topWidget: topWidget,
      bottomWidget: bottomWidget,
      useStampBadge: useStampBadge,
      leftAlign: leftAlign,
      icon: icon,
      selectable: false,
    );
  }
}
