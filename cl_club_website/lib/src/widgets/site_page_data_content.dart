import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_lib/ui_lib.dart' show PageData, PageDataContent;

import '../page_content/site_copy.dart';
import '../providers/page_hero_fallback_uri.dart';

/// A content page of the site: ui_lib's [PageDataContent] with the site's
/// default hero image, and its buttons following the site's routes.
///
/// [SitePageDataContent] takes a [PageData] assembled from an entity (a
/// venue) or from the copy; `PageDataScaffold` looks the copy up.
class SitePageDataContent extends ConsumerWidget {
  const SitePageDataContent({
    required this.pageData,
    super.key,
    this.activeContent,
    this.pastContent,
    this.heroIcon,
    this.useActiveSectionWrapper = true,
  });

  /// The page's copy.
  final PageData pageData;

  /// Content for the active section. If null, shows the empty state instead.
  final Widget? activeContent;

  /// Content for the past section.
  final Widget? pastContent;

  /// Optional icon to display instead of badge (e.g., map pin for venue).
  final IconData? heroIcon;

  /// If true, wraps activeContent in a section with its header.
  final bool useActiveSectionWrapper;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageDataContent(
      pageData: pageData,
      activeContent: activeContent,
      pastContent: pastContent,
      heroFallbackImageUri: ref.watch(pageHeroFallbackUriProvider),
      heroIcon: heroIcon,
      useActiveSectionWrapper: useActiveSectionWrapper,
      onNavigate: context.go,
      onEmptyStateAction: () => context.go(SiteCopy.routeContact),
    );
  }
}
