import 'package:cl_club_forms/cl_club_forms.dart'
    show LocationEditFormFields, VenueCreateForm, VenueFormFields;
import 'package:cl_club_venues/src/models/venue_form_helpers.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildVenueFormInitialValues', () {
    test('null venue → create defaults (all empty, toggles off)', () {
      final values = buildVenueFormInitialValues(null);
      expect(values, VenueCreateForm.emptyValues);
      expect(values[VenueFormFields.nameId], '');
      expect(values[VenueFormFields.isDefaultId], false);
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

      expect(values[VenueFormFields.nameId], 'Main Arena');
      expect(values[VenueFormFields.addressId], '1 Rink Rd');
      expect(values[VenueFormFields.descriptionId], 'desc');
      expect(values[VenueFormFields.mapUriId], 'https://maps.example/x');
      expect(values[VenueFormFields.isDefaultId], true);
      expect(values[VenueFormFields.isFeaturedId], false);
    });

    test('null optional fields normalize to empty strings', () {
      final venue = Venue(
        id: 2,
        name: 'Bare',
        createdAtUtc: DateTime.utc(2025),
        updatedAtUtc: DateTime.utc(2025),
      );

      final values = buildVenueFormInitialValues(venue);

      expect(values[VenueFormFields.addressId], '');
      expect(values[VenueFormFields.descriptionId], '');
      expect(values[VenueFormFields.mapUriId], '');
    });
  });

  group('Issue 104: buildLocationEditFormInitialValues', () {
    test('Issue 104: a venue gives its address and its map link', () {
      final venue = Venue(
        id: 1,
        name: 'Main Arena',
        address: '1 Rink Rd',
        mapUri: 'https://maps.example/x',
        createdAtUtc: DateTime.utc(2025),
        updatedAtUtc: DateTime.utc(2025),
      );

      expect(buildLocationEditFormInitialValues(venue), {
        LocationEditFormFields.addressId: '1 Rink Rd',
        LocationEditFormFields.mapUriId: 'https://maps.example/x',
      });
    });

    test('Issue 104: a venue with neither gives both empty', () {
      final venue = Venue(
        id: 2,
        name: 'Bare',
        createdAtUtc: DateTime.utc(2025),
        updatedAtUtc: DateTime.utc(2025),
      );

      expect(buildLocationEditFormInitialValues(venue), {
        LocationEditFormFields.addressId: '',
        LocationEditFormFields.mapUriId: '',
      });
    });

    test('Issue 104: no venue gives both empty', () {
      expect(buildLocationEditFormInitialValues(null), {
        LocationEditFormFields.addressId: '',
        LocationEditFormFields.mapUriId: '',
      });
    });
  });
}
