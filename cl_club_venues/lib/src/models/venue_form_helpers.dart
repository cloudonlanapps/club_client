import 'package:cl_club_forms/cl_club_forms.dart'
    show LocationEditFormFields, VenueCreateForm, VenueFormFields;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClVenuesMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart'
    show SdkErrorCode, ServerException, Venue;

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
    VenueFormFields.nameId: venue.name,
    VenueFormFields.addressId: venue.address ?? '',
    VenueFormFields.descriptionId: venue.description ?? '',
    VenueFormFields.mapUriId: venue.mapUri ?? '',
    VenueFormFields.isDefaultId: venue.isDefault,
    VenueFormFields.isFeaturedId: venue.isFeatured,
  };
}

/// Builds the `LocationEditForm.initialValues` map from [venue]'s address
/// and map link; each is empty when [venue] has none, or is null.
Map<String, dynamic> buildLocationEditFormInitialValues(Venue? venue) => {
  LocationEditFormFields.addressId: venue?.address ?? '',
  LocationEditFormFields.mapUriId: venue?.mapUri ?? '',
};

/// Bridges the venue forms' values to the SDK create/update calls, and the
/// server's refusals back to the forms.
class VenueFormSubmit {
  const VenueFormSubmit._();

  /// Shown on the Default venue switch when the club already has one.
  static const String defaultVenueExistsMessage =
      'A default venue already exists.';

  /// The fields of the create form the server refused with [error], as
  /// field id → message for the form's `showErrors`. Empty when the refusal
  /// names no field (the host then reports a failed create).
  static Map<String, String> createFieldErrors(Object error) {
    if (error is ServerException &&
        error.code == SdkErrorCode.defaultVenueExists) {
      return const {VenueFormFields.isDefaultId: defaultVenueExistsMessage};
    }
    return const {};
  }

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
      name: (values[VenueFormFields.nameId] as String).trim(),
      address: _nullIfEmpty(values[VenueFormFields.addressId]),
      description: _nullIfEmpty(values[VenueFormFields.descriptionId]),
      mapUri: _nullIfEmpty(values[VenueFormFields.mapUriId]),
      isDefault: values[VenueFormFields.isDefaultId] as bool? ?? false,
      isFeatured: values[VenueFormFields.isFeaturedId] as bool? ?? false,
    );
  }

  /// Update a venue's location (address + map link) from the location section
  /// editor's [values] (keyed by [LocationEditFormFields]). Sends only those
  /// two fields, leaving everything else untouched; a blank one is cleared.
  static Future<Venue> updateLocation({
    required int venueId,
    required Map<String, dynamic> values,
    required ClVenuesMasterNotifier notifier,
  }) {
    final address = _nullIfEmpty(values[LocationEditFormFields.addressId]);
    final mapUri = _nullIfEmpty(values[LocationEditFormFields.mapUriId]);
    return notifier.updateVenue(
      venueId,
      address: () => address,
      mapUri: () => mapUri,
    );
  }
}
