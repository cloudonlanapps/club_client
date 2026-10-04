/// Labels of the badges a venue card shows.
///
/// The public projection names the default venue itself
/// (`PublicVenue.primaryVenueBadge`); the member card, which reads the full
/// `Venue`, uses [defaultVenue].
abstract final class VenueBadgeLabels {
  /// The club's default venue.
  static const String defaultVenue = 'Default';

  /// A venue the club features.
  static const String featured = 'Featured';
}
