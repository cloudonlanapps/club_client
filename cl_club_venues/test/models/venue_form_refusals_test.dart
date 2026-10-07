import 'package:cl_club_forms/cl_club_forms.dart'
    show LocationEditFormFields, VenueFormFields;
import 'package:cl_club_venues/src/models/venue_form_helpers.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClVenuesMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records the location a section save sends.
class _RecordingVenues extends ClVenuesMasterNotifier {
  final List<({String? address, String? mapUri, bool sentBoth})> updated = [];

  @override
  Future<Venue> updateVenue(
    int id, {
    String? name,
    bool? isDefault,
    String? Function()? address,
    String? Function()? description,
    String? Function()? mapUri,
    bool? isFeatured,
  }) async {
    updated.add((
      address: address?.call(),
      mapUri: mapUri?.call(),
      sentBoth:
          address != null &&
          mapUri != null &&
          name == null &&
          description == null &&
          isDefault == null &&
          isFeatured == null,
    ));
    return Venue(
      id: id,
      name: 'Main Arena',
      createdAtUtc: DateTime.utc(2025),
      updatedAtUtc: DateTime.utc(2025),
    );
  }
}

void main() {
  group('Issue 55: VenueFormSubmit.createFieldErrors', () {
    test('Issue 55: a second default venue is refused on the Default venue '
        'switch', () {
      const refusal = ServerException(
        statusCode: 409,
        code: SdkErrorCode.defaultVenueExists,
        message: 'A default venue already exists',
      );

      expect(VenueFormSubmit.createFieldErrors(refusal), {
        VenueFormFields.isDefaultId: VenueFormSubmit.defaultVenueExistsMessage,
      });
    });

    test('Issue 55: any other failure names no field', () {
      const other = ServerException(
        statusCode: 500,
        code: 'INTERNAL',
        message: 'boom',
      );

      expect(VenueFormSubmit.createFieldErrors(other), isEmpty);
      expect(VenueFormSubmit.createFieldErrors(StateError('x')), isEmpty);
    });
  });

  group('Issue 55: VenueFormSubmit.updateLocation', () {
    test('Issue 55: reads the address and the map link from the form values '
        'and sends only those two', () async {
      final venues = _RecordingVenues();

      await VenueFormSubmit.updateLocation(
        venueId: 4,
        values: const {
          LocationEditFormFields.addressId: '1 Rink Rd',
          LocationEditFormFields.mapUriId: 'https://maps.example/x',
        },
        notifier: venues,
      );

      final sent = venues.updated.single;
      expect(sent.address, '1 Rink Rd');
      expect(sent.mapUri, 'https://maps.example/x');
      expect(sent.sentBoth, isTrue);
    });

    test('Issue 55: a blank field clears what the venue held', () async {
      final venues = _RecordingVenues();

      await VenueFormSubmit.updateLocation(
        venueId: 4,
        values: const {
          LocationEditFormFields.addressId: '',
          LocationEditFormFields.mapUriId: '',
        },
        notifier: venues,
      );

      final sent = venues.updated.single;
      expect(sent.address, isNull);
      expect(sent.mapUri, isNull);
      expect(sent.sentBoth, isTrue);
    });
  });
}
