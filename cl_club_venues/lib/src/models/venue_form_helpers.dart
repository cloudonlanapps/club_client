import 'package:cl_club_forms/cl_club_forms.dart'
    show LocationEditFormFields, VenueCreateForm, VenueFormFields;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClVenuesMasterNotifier, schemaFieldErrors;
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

  /// The server's name for a venue's name.
  static const String serverName = 'name';

  /// The server's name for a venue's address.
  static const String serverAddress = 'address';

  /// The server's name for a venue's description.
  static const String serverDescription = 'description';

  /// The server's name for a venue's map link.
  static const String serverMapUri = 'mapUri';

  /// The server's name for the default-venue flag.
  static const String serverIsDefault = 'isDefault';

  /// The server's name for the featured flag.
  static const String serverIsFeatured = 'isFeatured';

  /// The fields of a new venue, as the server names them in a schema
  /// rejection (club_client#114), each with the id of the create form's
  /// field that holds it.
  static const Map<String, String> createSchemaFieldIds = {
    serverName: VenueFormFields.nameId,
    serverAddress: VenueFormFields.addressId,
    serverDescription: VenueFormFields.descriptionId,
    serverMapUri: VenueFormFields.mapUriId,
    serverIsDefault: VenueFormFields.isDefaultId,
    serverIsFeatured: VenueFormFields.isFeaturedId,
  };

  /// The fields of a venue's location, as the server names them, each with
  /// the id of the location editor's field that holds it.
  static const Map<String, String> locationSchemaFieldIds = {
    serverAddress: LocationEditFormFields.addressId,
    serverMapUri: LocationEditFormFields.mapUriId,
  };

  /// The fields of the create form the server refused with [error], as
  /// field id → message for the form's `showErrors`, a schema rejection
  /// included (club_client#114). Empty when the refusal names no field (the
  /// host then reports a failed create).
  static Map<String, String> createFieldErrors(Object error) {
    if (error is ServerException &&
        error.code == SdkErrorCode.defaultVenueExists) {
      return const {VenueFormFields.isDefaultId: defaultVenueExistsMessage};
    }
    return schemaFieldErrors(error, createSchemaFieldIds);
  }

  /// The fields of the location editor the server refused with [error] at
  /// its schema, as field id → message. Empty when [error] names no field
  /// (the host then reports a failed save).
  static Map<String, String> locationFieldErrors(Object error) =>
      schemaFieldErrors(error, locationSchemaFieldIds);

  /// What the rename dialog shows on the name for a rename that failed with
  /// [error]: the server's reason when its schema rejects the name, else
  /// [fallback].
  static String renameRefusal(Object error, {required String fallback}) =>
      schemaFieldErrors(error, const {serverName: serverName})[serverName] ??
      fallback;

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
