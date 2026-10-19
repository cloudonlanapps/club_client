import 'package:cl_club_events/src/models/event_marketing_form_helpers.dart';
import 'package:cl_club_events/src/models/event_marketing_sections.dart';
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

Event _camp() => Event(
  id: 1,
  title: 'Summer camp',
  description: '',
  type: EventType.camp,
  visibility: Visibility.public,
  venueId: 1,
  startTimeUtc: DateTime.utc(2026, 6),
  endTimeUtc: DateTime.utc(2026, 6, 1, 2),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
  stamp: 'OLD',
  highlights: const ['Old highlight'],
);

void main() {
  group('Issue 1: the marketing forms map onto the event and its block', () {
    test('Issue 1: the basic form replaces the four fields; blanks clear', () {
      final event = EventMarketingSections.withBasic(_camp(), const {
        EventBasicMarketingFormFields.shortDescriptionId: 'Learn to skate',
        EventBasicMarketingFormFields.stampId: '',
        EventBasicMarketingFormFields.highlightsId: <String>[],
        EventBasicMarketingFormFields.includesId: ['Helmet'],
      });

      expect(event.shortDescription, 'Learn to skate');
      expect(event.stamp, isNull);
      expect(event.highlights, isNull);
      expect(event.includes, ['Helmet']);
    });

    test('Issue 1: the basic form starts from what the event holds', () {
      final values = buildEventBasicMarketingFormInitialValues(_camp());

      expect(values[EventBasicMarketingFormFields.stampId], 'OLD');
      expect(values[EventBasicMarketingFormFields.highlightsId], [
        {EventMarketingColumns.textId: 'Old highlight'},
      ]);
    });

    test('Issue 1: details keep the rest of the block and end the deadline '
        'at the close of its day', () {
      const stored = EventMarketing(fee: 500, durationText: 'old');
      final next = EventMarketingSections.withDetails(stored, {
        EventMarketingDetailsFormFields.durationTextId: '5 days',
        EventMarketingDetailsFormFields.registrationDeadlineId: DateTime(
          2026,
          11,
          30,
        ),
        EventMarketingDetailsFormFields.openSlotsId:
            EventMarketingDetailsFormFields.openSlotsFull,
      });

      expect(next.fee, 500, reason: 'another section is left alone');
      expect(next.durationText, '5 days');
      expect(next.hasOpenSlots, isFalse);
      expect(
        next.registrationDeadlineUtc,
        DateTime(2026, 11, 30, 23, 59, 59).toUtc(),
      );
      expect(
        buildEventMarketingDetailsFormInitialValues(
          next,
        )[EventMarketingDetailsFormFields.registrationDeadlineId],
        DateTime(2026, 11, 30),
        reason: 'the form reads back the day it saved',
      );
    });

    test('Issue 1: fees read the amounts as numbers', () {
      final next = EventMarketingSections.withFees(const EventMarketing(), {
        EventMarketingFeesFormFields.feeId: '4500',
        EventMarketingFeesFormFields.feeStructureId: [
          {
            EventMarketingColumns.nameId: 'Coaching',
            EventMarketingColumns.amountId: '4000',
            EventMarketingColumns.periodId: '',
          },
        ],
      });

      expect(next.fee, 4500);
      expect(next.feeStructure, [
        const FeeItem(name: 'Coaching', amount: 4000),
      ]);
    });

    test("Issue 1: a package's features are one a line", () {
      final next = EventMarketingSections.withPackages(const EventMarketing(), {
        EventMarketingRowsFormFields.rowsId: [
          {
            EventMarketingColumns.nameId: 'Season',
            EventMarketingColumns.amountId: '9000',
            EventMarketingColumns.descriptionId: '',
            EventMarketingColumns.featuresId: 'Ice time\n\n Kit ',
          },
        ],
      });

      expect(next.packageOffers!.single.features, ['Ice time', 'Kit']);
      expect(next.packageOffers!.single.description, isNull);
    });

    test('Issue 1: no title, no membership; no rows, no list', () {
      const stored = EventMarketing(
        clubMembership: ClubMembership(title: 'Members'),
        facilities: [Facility(name: 'Parking')],
      );

      final next = EventMarketingSections.withFacilities(
        EventMarketingSections.withMembership(stored, const {
          EventMarketingMembershipFormFields.titleId: '',
        }),
        const {EventMarketingRowsFormFields.rowsId: <Map<String, Object?>>[]},
      );

      expect(next.clubMembership, isNull);
      expect(next.facilities, isNull);
    });
  });
}
