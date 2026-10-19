import 'package:flutter/foundation.dart';

import 'page_cta_data.dart';
import 'page_empty_state_data.dart';
import 'page_hero_data.dart';
import 'page_section_header_data.dart';

/// Unified page data for list pages (programs, camps, events, coaches,
/// locations).
///
/// A host builds it from its own copy (the website from its ARB).
/// - Programs: pastSection is null (ongoing, no past/active distinction)
/// - Camps/One-offs: pastSection has value for past events section
/// - Coaches/Locations: simpler pages using hero, activeSection, emptyState,
///   cta
@immutable
class PageData {
  const PageData({
    required this.hero,
    required this.emptyState,
    this.activeSection,
    this.cta,
    this.pastSection,
    this.landingSection,
    this.errorTitle,
    this.cardLabels = const {},
  });

  final PageHeroData hero;

  /// Section header for active content. Null to skip section header
  /// (content is shown directly without header).
  final PageSectionHeaderData? activeSection;

  /// Section header for past events. Null for programs (no past section).
  final PageSectionHeaderData? pastSection;

  final PageEmptyStateData emptyState;

  /// CTA section data. Null if no CTA should be shown.
  final PageCtaData? cta;

  /// Section header for landing page section.
  final PageSectionHeaderData? landingSection;

  /// Error title shown when data fails to load.
  final String? errorTitle;

  /// Card labels for event/program cards (viewDetails, joinNow, etc.).
  final Map<String, String> cardLabels;

  PageData copyWith({
    PageHeroData? hero,
    PageSectionHeaderData? Function()? activeSection,
    PageSectionHeaderData? Function()? pastSection,
    PageEmptyStateData? emptyState,
    PageCtaData? Function()? cta,
    PageSectionHeaderData? Function()? landingSection,
    String? Function()? errorTitle,
    Map<String, String>? cardLabels,
  }) {
    return PageData(
      hero: hero ?? this.hero,
      activeSection: activeSection != null
          ? activeSection()
          : this.activeSection,
      pastSection: pastSection != null ? pastSection() : this.pastSection,
      emptyState: emptyState ?? this.emptyState,
      cta: cta != null ? cta() : this.cta,
      landingSection: landingSection != null
          ? landingSection()
          : this.landingSection,
      errorTitle: errorTitle != null ? errorTitle() : this.errorTitle,
      cardLabels: cardLabels ?? this.cardLabels,
    );
  }

  @override
  String toString() =>
      'PageData(hero: $hero, activeSection: $activeSection, pastSection: '
      '$pastSection, emptyState: $emptyState, cta: $cta, landingSection: '
      '$landingSection, errorTitle: $errorTitle, cardLabels: $cardLabels)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PageData &&
        other.hero == hero &&
        other.activeSection == activeSection &&
        other.pastSection == pastSection &&
        other.emptyState == emptyState &&
        other.cta == cta &&
        other.landingSection == landingSection &&
        other.errorTitle == errorTitle &&
        mapEquals(other.cardLabels, cardLabels);
  }

  @override
  int get hashCode => Object.hash(
    hero,
    activeSection,
    pastSection,
    emptyState,
    cta,
    landingSection,
    errorTitle,
    Object.hashAll(cardLabels.entries),
  );
}
