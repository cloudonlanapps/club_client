import 'package:cl_club_events/cl_club_events.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/public_events.dart';

void main() {
  group('Issue 53: a public event as the pages read it', () {
    test('Issue 53: a daily camp spans its COUNT of days', () {
      final view = testEventView(
        testPublicEvent(rrule: 'FREQ=DAILY;COUNT=6'),
      );

      expect(view.dateRange, '4 - 9 May 2026');
      expect(view.displayDateRange, '4 - 9 May 2026');
    });

    test('Issue 53: the marketing schedule text wins over the derived '
        'range', () {
      final view = testEventView(
        testPublicEvent(rrule: 'FREQ=DAILY;COUNT=6'),
        marketing: const EventMarketing(scheduleText: '4th - 9th May'),
      );

      expect(view.displayDateRange, '4th - 9th May');
      expect(view.effectiveSchedule, '4th - 9th May');
    });

    test('Issue 53: a weekly programme reads its days and clock times', () {
      final view = testEventView(
        testPublicEvent(
          type: EventType.programme,
          rrule: 'FREQ=WEEKLY;BYDAY=MO,TU',
          start: DateTime(2026, 5, 4, 16, 30),
          length: const Duration(minutes: 90),
        ),
      );

      expect(view.effectiveSchedule, 'Mon, Tue');
      expect(view.effectiveDuration, '4:30 PM - 6:00 PM');
      expect(view.effectiveTimings, ['4:30 PM - 6:00 PM']);
    });

    test('Issue 53: sessions become a labelled timetable', () {
      final view = testEventView(
        testPublicEvent(
          start: DateTime(2026, 5, 4, 7, 30),
          length: const Duration(minutes: 90),
          sessions: const [
            EventSession(name: 'Off-Ice Workout', periodMinutes: 30),
            EventSession(name: 'On-Ice', periodMinutes: 60),
          ],
        ),
      );

      expect(view.effectiveTimings, [
        '7:30 AM - 8:00 AM Off-Ice Workout',
        '8:00 AM - 9:00 AM On-Ice',
      ]);
    });

    test('Issue 53: the headline fee uses the club grouping', () {
      final view = testEventView(
        testPublicEvent(),
        marketing: const EventMarketing(fee: 150000),
      );

      expect(view.formattedFees, '1,50,000/-');
    });

    test('Issue 53: the call to action follows the event state', () {
      expect(testEventView(testPublicEvent()).ctaState, 'available');
      expect(
        testEventView(testPublicEvent(isPast: true)).ctaState,
        'completed',
      );
      expect(
        testEventView(
          testPublicEvent(),
          marketing: EventMarketing(
            registrationDeadlineUtc: DateTime.utc(2020),
          ),
        ).ctaState,
        'closed',
      );
    });

    test('Issue 53: eligibility windows read as ages at the start', () {
      final view = testEventView(
        testPublicEvent(
          dobOnOrBeforeUtc: DateTime.utc(2018, 5, 4),
          dobOnOrAfterUtc: DateTime.utc(2014, 5, 5),
        ),
      );

      expect(view.ageRange, '8-11');
    });

    test('Issue 53: an event is a highlight of its type', () {
      final view = testEventView(
        testPublicEvent(
          isFeatured: true,
          marketing: const EventMarketingBasic(
            shortDescription: 'Learn to skate',
            stamp: 'New',
          ),
        ),
      );

      final highlight = view.toHighlight();
      expect(highlight, isA<EventHighlight>());
      expect(highlight.id, 'pe-1');
      expect(highlight.type, HighlightType.camp);
      expect(highlight.subtitle, 'Learn to skate');
      expect(highlight.stamp, 'New');
      expect(highlight.isFeatured, isTrue);
    });
  });
}
