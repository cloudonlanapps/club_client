import 'package:cl_club_forms/src/widgets/event_schedule/programme_schedule_adjust_form_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Issue 61: ProgrammeScheduleAdjustFormValidators.from', () {
    const check = ProgrammeScheduleAdjustFormValidators.from;
    final options = [
      DateTime.utc(2030, 5, 13, 6),
      DateTime.utc(2030, 5, 16, 6),
    ];

    test('Issue 61: no session is refused as required', () {
      expect(
        check(null, options),
        ProgrammeScheduleAdjustFormValidators.fromRequiredMessage,
      );
    });

    test('Issue 61: each offered session start is accepted', () {
      for (final option in options) {
        expect(check(option, options), isNull);
      }
    });

    test('Issue 61: the same moment in local time is accepted', () {
      expect(check(options.last.toLocal(), options), isNull);
    });

    test('Issue 61: a moment that is not a session start is refused', () {
      const refused =
          ProgrammeScheduleAdjustFormValidators.fromNotASessionMessage;
      expect(
        check(options.first.add(const Duration(minutes: 1)), options),
        refused,
      );
      expect(check(DateTime.utc(2030, 5, 14, 6), options), refused);
    });

    test('Issue 61: with nothing offered any session is refused', () {
      expect(
        check(options.first, const []),
        ProgrammeScheduleAdjustFormValidators.fromNotASessionMessage,
      );
    });
  });

  group('Issue 61: ProgrammeScheduleAdjustFormValidators.venue', () {
    const check = ProgrammeScheduleAdjustFormValidators.venue;

    test('Issue 61: no venue is refused', () {
      expect(
        check(null),
        ProgrammeScheduleAdjustFormValidators.venueRequiredMessage,
      );
    });

    test('Issue 61: any venue id is accepted', () {
      expect(check(7), isNull);
      expect(check(0), isNull);
    });
  });
}
