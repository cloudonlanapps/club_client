import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/weekday_selector.dart'
    show WeekdayChip;
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/event_create_form_support.dart';
import '../support/form_harness.dart';

// EventCreateForm with the server, disabled, and laid out. Which points of
// issue 61 do not apply to the form is noted in
// event_create_form_contract_test.dart.

void main() {
  group('Issue 61: EventCreateForm and the server', () {
    testWidgets('Issue 61: what the server refuses shows on the title, the '
        'venue and the schedule, and inline', (tester) async {
      final form = await pumpCreateForm(tester, EventFormType.programme);

      await expectShowsServerErrors(tester, form, titleId);
      await expectShowsServerErrors(tester, form, venueId);
      await expectShowsServerErrors(tester, form, visibilityId);
      await expectShowsServerErrors(tester, form, scheduleId);
    });

    testWidgets('Issue 61: after a refusal the form validates and returns '
        'its values again', (tester) async {
      final initial = completeCreateValues(EventFormType.camp);
      final form = await pumpCreateForm(
        tester,
        EventFormType.camp,
        initial: initial,
      );

      form.showErrors(
        fieldErrors: const {
          titleId: 'That title is taken.',
          scheduleId: 'Too far ahead.',
        },
        formError: 'That clashes with another booking.',
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: fieldWithId(titleId),
          matching: find.text('That title is taken.'),
        ),
        findsOneWidget,
      );

      await enterField(tester, titleId, 'Summer Camp II');
      final values = form.validate();
      await tester.pumpAndSettle();

      expect(values, {...initial, titleId: 'Summer Camp II'});
      expect(find.text('That title is taken.'), findsNothing);
      expect(find.text('Too far ahead.'), findsNothing);
      expect(find.text('That clashes with another booking.'), findsNothing);
    });
  });

  group('Issue 61: EventCreateForm disabled', () {
    for (final type in EventFormType.values) {
      testWidgets('Issue 61: a disabled ${type.name} form answers nothing: '
          'title, selects and schedule', (tester) async {
        final initial = completeCreateValues(type);
        final form = await pumpCreateForm(
          tester,
          type,
          initial: initial,
          enabled: false,
        );

        await tester.tap(fieldWithId(titleId), warnIfMissed: false);
        await tester.pumpAndSettle();
        tester.testTextInput.enterText('Changed');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Private'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text('Public'), findsNothing);

        await tester.tap(find.text('Practice Rink'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text('Main Rink'), findsNothing);

        expect(
          tester
              .widget<ShadFormBuilderField<dynamic>>(fieldWithId(scheduleId))
              .enabled,
          isFalse,
        );
        if (type == EventFormType.camp) {
          await tester.tap(trainingDaysInput('4'), warnIfMissed: false);
          await tester.pumpAndSettle();
          tester.testTextInput.enterText('9');
          await tester.pumpAndSettle();
        }
        if (type == EventFormType.programme) {
          await tester.tap(
            find.byType(WeekdayChip).last,
            warnIfMissed: false,
          );
          await tester.pumpAndSettle();
        }

        expect(form.isDirty, isFalse);
        expect(form.validate(), initial);
      });
    }
  });

  group('Issue 61: EventCreateForm layout', () {
    for (final type in EventFormType.values) {
      testWidgets('Issue 61: a ${type.name} form fits a phone, Visibility '
          'above Venue', (tester) async {
        await pumpCreateForm(
          tester,
          type,
          initial: completeCreateValues(type)
            ..[titleId] =
                'A very long title for an event that goes on '
                'and on past the edge of a phone',
          size: kPhoneSurface,
        );

        expect(tester.takeException(), isNull);
        final visibility = tester.getRect(fieldWithId(visibilityId));
        final venue = tester.getRect(fieldWithId(venueId));
        expect(venue.top, greaterThan(visibility.bottom));
        expect(venue.left, visibility.left);
      });
    }

    testWidgets('Issue 61: on a wide surface Visibility and Venue share a '
        'row, equally wide', (tester) async {
      await pumpCreateForm(tester, EventFormType.camp);

      final visibility = tester.getRect(fieldWithId(visibilityId));
      final venue = tester.getRect(fieldWithId(venueId));
      expect(venue.top, visibility.top);
      expect(venue.left, greaterThan(visibility.right));
    });

    for (final type in EventFormType.values) {
      testWidgets('Issue 61: a ${type.name} form draws no heading and no '
          'button of its own', (tester) async {
        await pumpCreateForm(tester, type, initial: completeCreateValues(type));

        expectNoHostChrome(tester);
        for (final heading in [
          'New ${type.label}',
          'Create ${type.label}',
          'Create',
          'Cancel',
        ]) {
          expect(find.text(heading), findsNothing, reason: heading);
        }
      });
    }

    testWidgets('Issue 61: a programme with an end date shows Clear, an '
        'action of its schedule, and no other button', (tester) async {
      await pumpCreateForm(
        tester,
        EventFormType.programme,
        initial: completeCreateValues(EventFormType.programme)
          ..[scheduleId] = ProgrammeScheduleData(
            weekdays: const {1},
            startDate: DateTime(2030, 7),
            endDate: DateTime(2030, 9),
            hasNoEndDate: false,
            sessionStartTime: nineOClock,
          ),
      );

      expect(find.widgetWithText(ShadButton, 'Clear'), findsOneWidget);
      expectNoHostChrome(tester, allowedButtonTexts: {'Clear'});
    });
  });
}
