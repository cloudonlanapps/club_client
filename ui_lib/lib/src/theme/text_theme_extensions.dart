import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Extension on ShadTextTheme providing standardized text styles across the
/// app.
///
/// Usage:
/// ```dart
/// final theme = ShadTheme.of(context);
/// Text('Title', style: theme.textTheme.heroTitle(isMobile: isMobile));
/// Text('Accept', style: theme.textTheme.buttonLabel);
/// ```
extension ClubTextTheme on ShadTextTheme {
  /// Compact label for action buttons (e.g., Approve, Withdraw).
  /// 11px, w500 — derived from `small` with reduced font size.
  TextStyle get buttonLabel => small.copyWith(fontSize: 11);

  /// Hero/page title style - large bold text for page headers.
  /// Used in: hero sections, page titles.
  /// Mobile: 28px, Desktop: 40px
  TextStyle heroTitle({required bool isMobile}) => TextStyle(
    fontSize: isMobile ? 28 : 40,
    fontWeight: FontWeight.bold,
  );

  /// Section title style - bold text for major sections.
  /// Used in: fee structure, batch timings, facilities, packages, etc.
  /// Mobile: 24px, Desktop: 32px
  TextStyle sectionTitle({required bool isMobile}) => TextStyle(
    fontSize: isMobile ? 24 : 32,
    fontWeight: FontWeight.bold,
  );

  /// Subsection title style - bold text for smaller sections.
  /// Used in: highlights, fees card, eligibility, CTA.
  /// Mobile: 20px, Desktop: 24px
  TextStyle subsectionTitle({required bool isMobile}) => TextStyle(
    fontSize: isMobile ? 20 : 24,
    fontWeight: FontWeight.bold,
  );

  /// Badge text style - small uppercase text for badges/tags.
  /// Used in: section badges, event type badges.
  /// Fixed: 11px with letter spacing
  TextStyle get badgeText => const TextStyle(
    fontSize: 11,
    letterSpacing: 1.5,
    fontWeight: FontWeight.w600,
  );

  /// Description text style - muted text for descriptions.
  /// Used in: section descriptions, subtitles.
  /// Mobile: 14px, Desktop: 16px
  TextStyle sectionDescription({required bool isMobile}) => muted.copyWith(
    fontSize: isMobile ? 14 : 16,
  );

  /// Hero subtitle style - lighter text below hero titles.
  /// Used in: hero sections, landing page.
  /// Mobile: 14px, Desktop: 18px
  TextStyle heroSubtitle({required bool isMobile, required Color color}) =>
      TextStyle(
        fontSize: isMobile ? 14 : 18,
        color: color.withValues(alpha: 0.8),
      );

  /// Large price display style - prominent pricing.
  /// Used in: fees section hero price.
  /// Mobile: 36px, Desktop: 48px
  TextStyle priceHero({required bool isMobile, required Color color}) =>
      TextStyle(
        fontSize: isMobile ? 36 : 48,
        fontWeight: FontWeight.bold,
        color: color,
      );

  /// Medium price display style - package/offer pricing.
  /// Used in: package offers, price cards.
  /// Fixed: 28px
  TextStyle priceMedium(Color color) => TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: color,
  );

  /// Small price display style - inline pricing.
  /// Used in: event cards, compact views.
  /// Fixed: 20px
  TextStyle priceSmall(Color color) => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: color,
  );

  /// Card title style - medium bold text for cards.
  /// Used in: event cards, hero event cards.
  /// Compact: 24px, Full: 36px
  TextStyle cardTitle({required bool compact}) => TextStyle(
    fontSize: compact ? 24 : 36,
    fontWeight: FontWeight.bold,
  );

  /// Event card title on overlay - with custom color.
  /// Used in: camp/oneoff event cards with image background.
  TextStyle eventCardTitle({required bool isMobile, required Color color}) =>
      TextStyle(
        color: color,
        fontSize: isMobile ? 18 : 22,
        fontWeight: FontWeight.bold,
      );

  /// Event card tagline on overlay - with custom color.
  /// Used in: camp/oneoff event cards with image background.
  TextStyle eventCardTagline({required bool isMobile, required Color color}) =>
      TextStyle(
        color: color.withValues(alpha: 0.9),
        fontSize: isMobile ? 12 : 14,
      );
}
