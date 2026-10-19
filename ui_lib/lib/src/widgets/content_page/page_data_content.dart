import 'package:flutter/material.dart';

import '../../constants/breakpoints.dart';
import '../../models/page_data.dart';
import 'active_section.dart';
import 'cta_section.dart';
import 'empty_state_section.dart';
import 'page_hero.dart';
import 'past_section.dart';

/// Renders a content page: hero, sections, and CTA.
///
/// Builds, in order:
/// 1. the hero from `pageData.hero`, with [heroFallbackImageUri] when the
///    page has no image of its own;
/// 2. the active section header and [activeContent], or the empty state when
///    [activeContent] is null;
/// 3. the past section header and [pastContent], when both are there;
/// 4. the CTA section, when `pageData.cta` is set.
///
/// It navigates nowhere itself: the CTA's routes go to [onNavigate] and the
/// empty state's button to [onEmptyStateAction].
class PageDataContent extends StatelessWidget {
  const PageDataContent({
    required this.pageData,
    super.key,
    this.activeContent,
    this.pastContent,
    this.heroFallbackImageUri,
    this.heroTopWidget,
    this.heroBottomWidget,
    this.heroLeftAlign = false,
    this.heroUseStampBadge = false,
    this.heroIcon,
    this.useActiveSectionWrapper = true,
    this.onNavigate,
    this.onEmptyStateAction,
  });

  /// The page's copy.
  final PageData pageData;

  /// Content for the active section. If null, shows the empty state instead.
  final Widget? activeContent;

  /// Content for the past section. Only shown if `pageData.pastSection` is
  /// set too.
  final Widget? pastContent;

  /// The hero image when the page has none of its own (a site's default).
  final String? heroFallbackImageUri;

  /// Optional widget displayed above the hero badge/title (e.g., info cards).
  final Widget? heroTopWidget;

  /// Optional widget displayed below the hero description (e.g., info cards).
  final Widget? heroBottomWidget;

  /// If true, hero content is left-aligned instead of centered.
  final bool heroLeftAlign;

  /// If true, uses StampBadge style instead of ShadBadge.outline for the badge.
  final bool heroUseStampBadge;

  /// Optional icon to display instead of badge (e.g., map pin for venue).
  final IconData? heroIcon;

  /// If true, wraps activeContent in [ActiveSection] with section header.
  /// Set to false for detail pages where content provides its own structure.
  final bool useActiveSectionWrapper;

  /// Called with the route of a CTA button.
  final ValueChanged<String>? onNavigate;

  /// Called when the empty state's button is pressed.
  final VoidCallback? onEmptyStateAction;

  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.sizeOf(context).width <
        Breakpoints.contentPageMobileMaxWidth;
    final active = activeContent;
    final past = pastContent;
    final activeSection = pageData.activeSection;
    final pastSection = pageData.pastSection;
    final cta = pageData.cta;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PageHero(
          data: pageData.hero,
          fallbackImageUri: heroFallbackImageUri,
          topWidget: heroTopWidget,
          bottomWidget: heroBottomWidget,
          leftAlign: heroLeftAlign,
          useStampBadge: heroUseStampBadge,
          icon: heroIcon,
        ),
        if (active == null)
          EmptyStateSection(
            data: pageData.emptyState,
            isMobile: isMobile,
            onAction: onEmptyStateAction,
          )
        else if (useActiveSectionWrapper && activeSection != null)
          ActiveSection(
            sectionData: activeSection,
            isMobile: isMobile,
            child: active,
          )
        else
          active,
        if (past != null && pastSection != null)
          PastSection(
            sectionData: pastSection,
            isMobile: isMobile,
            child: past,
          ),
        if (cta != null)
          CtaSection(data: cta, isMobile: isMobile, onNavigate: onNavigate),
        const SizedBox(height: 40),
      ],
    );
  }
}
