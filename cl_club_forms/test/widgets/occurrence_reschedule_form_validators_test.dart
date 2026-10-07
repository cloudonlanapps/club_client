import 'package:cl_club_forms/src/widgets/occurrence_reschedule/occurrence_reschedule_form_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const check = OccurrenceRescheduleFormValidators.venue;

  test('Issue 61: venue refuses no venue', () {
    expect(
      check(null),
      OccurrenceRescheduleFormValidators.venueRequiredMessage,
    );
    expect(check(null), 'Venue is required');
  });

  test('Issue 61: venue accepts any venue id', () {
    expect(check(7), isNull);
    expect(check(0), isNull);
  });
}
