import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _six = ShadTimeOfDay(hour: 18, minute: 0, second: 0);

OneOffScheduleData _at(DateTime date, ShadTimeOfDay time) =>
    OneOffScheduleData(date: date, startTime: time);

void main() {
  group('OneOffScheduleFormValidators.venue', () {
    test('Issue 61: no venue is refused with the venue message', () {
      expect(
        OneOffScheduleFormValidators.venue(null),
        OneOffScheduleFormValidators.venueRequiredMessage,
      );
      expect(
        OneOffScheduleFormValidators.venueRequiredMessage,
        'Please select a venue',
      );
    });

    test('Issue 61: any venue id is accepted, zero included', () {
      expect(OneOffScheduleFormValidators.venue(7), isNull);
      expect(OneOffScheduleFormValidators.venue(0), isNull);
    });
  });

  group('OneOffScheduleFormValidators.startOf', () {
    test('Issue 61: a schedule without a date has no start', () {
      expect(
        OneOffScheduleFormValidators.startOf(
          const OneOffScheduleData(startTime: _six),
        ),
        isNull,
      );
    });

    test('Issue 61: a schedule without a start time has no start', () {
      expect(
        OneOffScheduleFormValidators.startOf(
          OneOffScheduleData(date: DateTime(2030, 5, 14)),
        ),
        isNull,
      );
    });

    test('Issue 61: the start is the date at the start time, to the minute, '
        'whatever time of day the date itself carries', () {
      expect(
        OneOffScheduleFormValidators.startOf(
          OneOffScheduleData(
            date: DateTime(2030, 5, 14, 23, 59, 59),
            startTime: const ShadTimeOfDay(hour: 9, minute: 5, second: 40),
          ),
        ),
        DateTime(2030, 5, 14, 9, 5),
      );
    });
  });

  group('OneOffScheduleFormValidators.notEarlier', () {
    final present = DateTime(2030, 5, 14, 18);

    test('Issue 61: a start one minute earlier is refused with the '
        'postpone-only message', () {
      expect(
        OneOffScheduleFormValidators.notEarlier(
          _at(
            DateTime(2030, 5, 14),
            const ShadTimeOfDay(hour: 17, minute: 59, second: 0),
          ),
          present,
        ),
        OneOffScheduleFormValidators.postponeOnlyMessage,
      );
    });

    test('Issue 61: an earlier day at a later time of day is refused', () {
      expect(
        OneOffScheduleFormValidators.notEarlier(
          _at(
            DateTime(2030, 5, 13),
            const ShadTimeOfDay(hour: 23, minute: 0, second: 0),
          ),
          present,
        ),
        OneOffScheduleFormValidators.postponeOnlyMessage,
      );
    });

    test('Issue 61: the present start itself is accepted', () {
      expect(
        OneOffScheduleFormValidators.notEarlier(
          _at(DateTime(2030, 5, 14), _six),
          present,
        ),
        isNull,
      );
    });

    test('Issue 61: a later start is accepted', () {
      expect(
        OneOffScheduleFormValidators.notEarlier(
          _at(
            DateTime(2030, 5, 14),
            const ShadTimeOfDay(hour: 18, minute: 1, second: 0),
          ),
          present,
        ),
        isNull,
      );
      expect(
        OneOffScheduleFormValidators.notEarlier(
          _at(
            DateTime(2030, 5, 15),
            const ShadTimeOfDay(hour: 6, minute: 0, second: 0),
          ),
          present,
        ),
        isNull,
      );
    });

    test('Issue 61: with no present start nothing is refused', () {
      expect(
        OneOffScheduleFormValidators.notEarlier(
          _at(DateTime(1999), _six),
          null,
        ),
        isNull,
      );
    });

    test(
      'Issue 61: an incomplete schedule is left to the field validators',
      () {
        expect(
          OneOffScheduleFormValidators.notEarlier(
            OneOffScheduleData(date: DateTime(1999)),
            present,
          ),
          isNull,
        );
        expect(
          OneOffScheduleFormValidators.notEarlier(
            const OneOffScheduleData(startTime: _six),
            present,
          ),
          isNull,
        );
      },
    );

    test('Issue 61: a present start given in UTC is compared as the same '
        'instant', () {
      final utc = present.toUtc();
      expect(
        OneOffScheduleFormValidators.notEarlier(
          _at(DateTime(2030, 5, 14), _six),
          utc,
        ),
        isNull,
      );
      expect(
        OneOffScheduleFormValidators.notEarlier(
          _at(
            DateTime(2030, 5, 14),
            const ShadTimeOfDay(hour: 17, minute: 59, second: 0),
          ),
          utc,
        ),
        OneOffScheduleFormValidators.postponeOnlyMessage,
      );
    });
  });
}
