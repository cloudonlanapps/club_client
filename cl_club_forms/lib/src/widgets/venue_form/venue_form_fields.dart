/// Field-id constants of the `ShadForm` inside `VenueCreateForm`. The
/// caller's adapter (`cl_club_venues` `venue_form_helpers`) reads the form's
/// values by them.
class VenueFormFields {
  const VenueFormFields._();

  /// The venue's name.
  static const String nameId = 'name';

  /// The free-text address.
  static const String addressId = 'address';

  /// What the venue is like.
  static const String descriptionId = 'description';

  /// The link to the venue on a map.
  static const String mapUriId = 'mapUri';

  /// Whether this is the club's default venue.
  static const String isDefaultId = 'isDefault';

  /// Whether the venue is featured on the website.
  static const String isFeaturedId = 'isFeatured';
}
