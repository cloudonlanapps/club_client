import 'package:club_sdk_2/club_sdk_2.dart' show EventType;

/// A landing event section's copy when the site's strings give no section
/// header.
typedef LandingEventsSectionCopy = ({
  String badge,
  String title,
  String description,
  String buttonText,
});

/// The fallback copy of each landing event section.
abstract final class LandingEventsSectionFallback {
  /// The copy for [type].
  static LandingEventsSectionCopy of(EventType type) => switch (type) {
    EventType.camp => (
      badge: 'LEARNING CAMPS',
      title: 'Upcoming Camps',
      description:
          'Learn with our professional coaches. Intensive '
          'training camps designed for all skill levels.',
      buttonText: 'Explore All Camps',
    ),
    EventType.programme => (
      badge: 'TRAINING SESSIONS',
      title: 'Programs For Everyone',
      description:
          'From beginners to competitive athletes, ages 5 to adults. Expert '
          'coaching with 4 experienced coaches per batch.',
      buttonText: 'Explore All Programs',
    ),
    EventType.oneOff => (
      badge: 'CLUB EVENTS',
      title: 'Special Events',
      description:
          'Discover unique experiences and special activities organized by '
          'our club throughout the year.',
      buttonText: 'View All Events',
    ),
  };
}
