import 'package:cl_club_forms/cl_club_forms.dart' show VenueCreateForm;
import 'package:cl_club_venues/src/models/venue_form_helpers.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildVenueFormInitialValues', () {
    test('null venue → create defaults (all empty, toggles off)', () {
      final values = buildVenueFormInitialValues(null);
      expect(values, VenueCreateForm.emptyValues);
      expect(values[VenueCreateForm.nameId], '');
      expect(values[VenueCreateForm.isDefaultId], false);
    });

    test('populates from an existing venue', () {
      final venue = Venue(
        id: 1,
        name: 'Main Arena',
        address: '1 Rink Rd',
        description: 'desc',
        mapUri: 'https://maps.example/x',
        isDefault: true,
        isFeatured: false,
        createdAtUtc: DateTime.utc(2025),
        updatedAtUtc: DateTime.utc(2025),
      );

      final values = buildVenueFormInitialValues(venue);

      expect(values[VenueCreateForm.nameId], 'Main Arena');
      expect(values[VenueCreateForm.addressId], '1 Rink Rd');
      expect(values[VenueCreateForm.descriptionId], 'desc');
      expect(values[VenueCreateForm.mapUriId], 'https://maps.example/x');
      expect(values[VenueCreateForm.isDefaultId], true);
      expect(values[VenueCreateForm.isFeaturedId], false);
    });

    test('null optional fields normalize to empty strings', () {
      final venue = Venue(
        id: 2,
        name: 'Bare',
        createdAtUtc: DateTime.utc(2025),
        updatedAtUtc: DateTime.utc(2025),
      );

      final values = buildVenueFormInitialValues(venue);

      expect(values[VenueCreateForm.addressId], '');
      expect(values[VenueCreateForm.descriptionId], '');
      expect(values[VenueCreateForm.mapUriId], '');
    });
  });
}
