/// Keys of the label map public event cards read, and each label's text
/// when the host supplies none.
abstract final class PublicEventCardLabels {
  static const String past = 'past';
  static const String registrationsOpen = 'registrationsOpen';
  static const String registrationsClosed = 'registrationsClosed';
  static const String venueTbd = 'venueTbd';
  static const String ageRangePrefix = 'ageRangePrefix';
  static const String whatsIncluded = 'whatsIncluded';
  static const String viewGallery = 'viewGallery';
  static const String viewDetails = 'viewDetails';

  /// Text for each key when the host's map lacks it.
  static const Map<String, String> defaults = {
    past: 'Past',
    registrationsOpen: 'Registrations Open',
    registrationsClosed: 'Registration Closed',
    venueTbd: 'Venue TBD',
    ageRangePrefix: 'For ages ',
    whatsIncluded: "What's Included:",
    viewGallery: 'View Gallery',
    viewDetails: 'View Details',
  };

  /// The label for [key] from [labels], else its default.
  static String of(Map<String, String> labels, String key) =>
      labels[key] ?? defaults[key]!;
}
