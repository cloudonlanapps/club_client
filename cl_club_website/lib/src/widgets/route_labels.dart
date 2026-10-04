import '../l10n/site_strings.dart';

/// The navigation label for a top-level route segment, from the site's copy.
///
/// Null for a segment with no label of its own; callers format the segment.
String? routeLabel(SiteStrings strings, String segment) => switch (segment) {
  'programs' => strings.navPrograms,
  'events' => strings.navEvents,
  'one-off' => strings.navOneOff,
  'coaches' => strings.navCoaches,
  'rinks' => strings.navRinks,
  'about-us' => strings.navAboutUs,
  'contact-us' => strings.navContactUs,
  _ => null,
};
