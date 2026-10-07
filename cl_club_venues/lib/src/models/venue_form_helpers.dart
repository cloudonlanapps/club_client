import 'package:cl_club_forms/cl_club_forms.dart'
    show LocationEditResult, VenueCreateForm;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClVenuesMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart' show Venue;

/// SDK adapter for the venue create form — the one place that bridges the
/// form's flat `Map<String, dynamic>` to the `cl_remote_store` create call.
///
/// The form widget ([VenueCreateForm]) is SDK-free; this helper owns the
/// translation. Mirrors `cl_club_members` `user_form_helpers.dart` /
/// `group_form_helpers.dart`.

/// Builds the `VenueCreateForm.initialValues` map from a [Venue] (or create
/// defaults when null). Mirrors `buildUserFormInitialValues` /
/// `buildGroupFormInitialValues`.
Map<String, dynamic> buildVenueFormInitialValues(Venue? venue) {
  if (venue == null) return VenueCreateForm.emptyValues;
  return {
    VenueCreateForm.nameId: venue.name,
    VenueCreateForm.addressId: venue.address ?? '',
    VenueCreateForm.descriptionId: venue.description ?? '',
    VenueCreateForm.mapUriId: venue.mapUri ?? '',
    VenueCreateForm.isDefaultId: venue.isDefault,
    VenueCreateForm.isFeaturedId: venue.isFeatured,
  };
}

class VenueFormSubmit {
  const VenueFormSubmit._();

  static String? _nullIfEmpty(Object? v) {
    final s = (v as String?)?.trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  /// Create a new venue from the form values.
  static Future<Venue> create({
    required Map<String, dynamic> values,
    required ClVenuesMasterNotifier notifier,
  }) {
    return notifier.createVenue(
      name: (values[VenueCreateForm.nameId] as String).trim(),
      address: _nullIfEmpty(values[VenueCreateForm.addressId]),
      description: _nullIfEmpty(values[VenueCreateForm.descriptionId]),
      mapUri: _nullIfEmpty(values[VenueCreateForm.mapUriId]),
      isDefault: values[VenueCreateForm.isDefaultId] as bool? ?? false,
      isFeatured: values[VenueCreateForm.isFeaturedId] as bool? ?? false,
    );
  }

  /// Update a venue's location (address + map link) from the location section
  /// editor. Sends only those two fields, leaving everything else untouched.
  static Future<Venue> updateLocation({
    required int venueId,
    required LocationEditResult result,
    required ClVenuesMasterNotifier notifier,
  }) {
    return notifier.updateVenue(
      venueId,
      address: () => result.address.isEmpty ? null : result.address,
      mapUri: () => result.mapUri.isEmpty ? null : result.mapUri,
    );
  }
}
