import 'package:cl_club_forms/cl_club_forms.dart' show VenueFormValidators;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Issue 61: VenueFormValidators.name', () {
    test('Issue 61: an empty or blank name is refused as the venue name', () {
      expect(VenueFormValidators.name(''), 'Venue name is required');
      expect(VenueFormValidators.name('  \t'), 'Venue name is required');
    });

    test('Issue 61: a name of one character is refused', () {
      expect(VenueFormValidators.name('A'), 'At least 2 characters');
    });

    test('Issue 61: the length is counted after trimming', () {
      expect(VenueFormValidators.name('  A  '), 'At least 2 characters');
    });

    test('Issue 61: a name of two characters or more passes', () {
      expect(VenueFormValidators.name('R1'), isNull);
      expect(VenueFormValidators.name(' Main Arena '), isNull);
    });
  });
}
