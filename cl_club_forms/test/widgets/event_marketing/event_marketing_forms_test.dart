import 'package:cl_calendar/cl_calendar.dart' show CLDatePickerFormField;
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/event_marketing/event_basic_marketing_form.dart'
    show EventBasicMarketingFormState;
import 'package:cl_club_forms/src/widgets/event_marketing/event_marketing_details_form.dart'
    show EventMarketingDetailsFormState;
import 'package:cl_club_forms/src/widgets/event_marketing/event_marketing_membership_form.dart'
    show EventMarketingMembershipFormState;
import 'package:cl_club_forms/src/widgets/event_marketing/event_marketing_rows_form.dart'
    show EventMarketingRowsFormState;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/date_picker_harness.dart';

Future<void> _pump(WidgetTester tester, Widget form) async {
  tester.view.physicalSize = const Size(1280, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(body: SingleChildScrollView(child: form)),
    ),
  );
  await tester.pumpAndSettle();
}

const Map<String, Object?> _basic = {
  EventBasicMarketingFormFields.shortDescriptionId: ' Five mornings ',
  EventBasicMarketingFormFields.stampId: 'New',
  EventBasicMarketingFormFields.highlightsId: [
    {EventMarketingColumns.textId: 'Skating basics'},
    {EventMarketingColumns.textId: '  '},
  ],
  EventBasicMarketingFormFields.includesId: <Map<String, Object?>>[],
};

void main() {
  group('Issue 1: the basic marketing form', () {
    testWidgets('Issue 1: returns texts trimmed and lists without blanks', (
      tester,
    ) async {
      final key = GlobalKey<EventBasicMarketingFormState>();
      await _pump(
        tester,
        EventBasicMarketingForm(key: key, initialValues: _basic),
      );

      expect(key.currentState!.validate(), {
        EventBasicMarketingFormFields.shortDescriptionId: 'Five mornings',
        EventBasicMarketingFormFields.stampId: 'New',
        EventBasicMarketingFormFields.highlightsId: ['Skating basics'],
        EventBasicMarketingFormFields.includesId: <String>[],
      });
      expect(key.currentState!.isDirty, isFalse);
    });

    testWidgets('Issue 1: an added row shows in the draft and makes it dirty', (
      tester,
    ) async {
      final key = GlobalKey<EventBasicMarketingFormState>();
      var changes = 0;
      await _pump(
        tester,
        EventBasicMarketingForm(
          key: key,
          initialValues: _basic,
          onChanged: () => changes++,
        ),
      );

      await tester.tap(find.text('Add item'));
      await tester.pumpAndSettle();
      final inputs = find.byType(EditableText);
      await tester.enterText(inputs.last, 'Helmet on loan');
      await tester.pumpAndSettle();

      expect(changes, greaterThan(0));
      expect(key.currentState!.isDirty, isTrue);
      expect(
        key.currentState!.draft[EventBasicMarketingFormFields.includesId],
        ['Helmet on loan'],
      );
    });

    testWidgets('Issue 1: a stamp over the limit is refused', (tester) async {
      final key = GlobalKey<EventBasicMarketingFormState>();
      await _pump(
        tester,
        EventBasicMarketingForm(
          key: key,
          initialValues: {
            ..._basic,
            EventBasicMarketingFormFields.stampId: 'x' * 61,
          },
        ),
      );

      expect(key.currentState!.validate(), isNull);
      await tester.pump();
      expect(find.text('At most 60 characters.'), findsOneWidget);
    });
  });

  group('Issue 1: the marketing rows form', () {
    testWidgets('Issue 1: a row without its required column is refused', (
      tester,
    ) async {
      final key = GlobalKey<EventMarketingRowsFormState>();
      await _pump(
        tester,
        EventMarketingRowsForm(
          key: key,
          columns: EventMarketingColumns.packages,
          addLabel: 'Add package',
          required: const {
            EventMarketingColumns.nameId,
            EventMarketingColumns.amountId,
          },
          initialRows: const [
            {EventMarketingColumns.nameId: 'Full season'},
          ],
        ),
      );

      expect(key.currentState!.validate(), isNull);
      await tester.pump();
      expect(find.text('Every row needs a price.'), findsOneWidget);
    });

    testWidgets('Issue 1: a removed row leaves the list', (tester) async {
      final key = GlobalKey<EventMarketingRowsFormState>();
      await _pump(
        tester,
        EventMarketingRowsForm(
          key: key,
          columns: EventMarketingColumns.offers,
          addLabel: 'Add offer',
          required: const {EventMarketingColumns.titleId},
          initialRows: const [
            {EventMarketingColumns.titleId: 'Early bird'},
            {EventMarketingColumns.titleId: 'Siblings'},
          ],
        ),
      );

      await tester.tap(find.byIcon(LucideIcons.trash2).first);
      await tester.pumpAndSettle();

      final rows =
          key.currentState!.validate()![EventMarketingRowsFormFields.rowsId]
              as List<Map<String, Object?>>;
      expect(rows.map((row) => row[EventMarketingColumns.titleId]), [
        'Siblings',
      ]);
    });
  });

  group('Issue 388: the marketing date cells', () {
    testWidgets("Issue 388: an offer's Valid until opens the calendar, "
        'shows and returns the picked day, and its x empties it', (
      tester,
    ) async {
      final key = GlobalKey<EventMarketingRowsFormState>();
      await _pump(
        tester,
        EventMarketingRowsForm(
          key: key,
          columns: EventMarketingColumns.offers,
          addLabel: 'Add offer',
          initialRows: [
            {
              EventMarketingColumns.titleId: 'Early bird',
              EventMarketingColumns.validUntilId: DateTime(2026, 5, 15),
            },
          ],
        ),
      );
      expect(find.byType(CLDatePickerFormField), findsOneWidget);
      expect(key.currentState!.isDirty, isFalse);

      await pickDayOn(tester, find.text('15 May 2026'), 20);

      expect(find.text('20 May 2026'), findsOneWidget);
      List<Map<String, Object?>> rows() =>
          key.currentState!.validate()![EventMarketingRowsFormFields.rowsId]
              as List<Map<String, Object?>>;
      final picked =
          rows().single[EventMarketingColumns.validUntilId]! as DateTime;
      expect([picked.year, picked.month, picked.day], [2026, 5, 20]);

      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pumpAndSettle();
      expect(find.text('20 May 2026'), findsNothing);
      expect(find.text('No end'), findsOneWidget);
      expect(rows().single[EventMarketingColumns.validUntilId], isNull);
    });

    testWidgets('Issue 388: the registration deadline opens the calendar '
        'and returns the picked day', (tester) async {
      final key = GlobalKey<EventMarketingDetailsFormState>();
      await _pump(
        tester,
        EventMarketingDetailsForm(
          key: key,
          initialValues: {
            EventMarketingDetailsFormFields.registrationDeadlineId: DateTime(
              2026,
              5,
              15,
            ),
          },
        ),
      );
      expect(find.byType(CLDatePickerFormField), findsOneWidget);
      expect(key.currentState!.isDirty, isFalse);

      await pickDayOn(tester, find.text('15 May 2026'), 20);

      expect(find.text('20 May 2026'), findsOneWidget);
      final picked =
          key.currentState!.validate()![EventMarketingDetailsFormFields
                  .registrationDeadlineId]!
              as DateTime;
      expect([picked.year, picked.month, picked.day], [2026, 5, 20]);
    });
  });

  group('Issue 1: the club membership form', () {
    testWidgets('Issue 1: details without a title are refused', (
      tester,
    ) async {
      final key = GlobalKey<EventMarketingMembershipFormState>();
      await _pump(
        tester,
        EventMarketingMembershipForm(
          key: key,
          initialValues: const {
            EventMarketingMembershipFormFields.descriptionId: 'Join us',
          },
        ),
      );

      expect(key.currentState!.validate(), isNull);
      await tester.pump();
      expect(
        find.text(EventMarketingMembershipForm.titleNeeded),
        findsOneWidget,
      );
    });

    testWidgets('Issue 1: an empty form is a valid no membership', (
      tester,
    ) async {
      final key = GlobalKey<EventMarketingMembershipFormState>();
      await _pump(
        tester,
        EventMarketingMembershipForm(key: key, initialValues: const {}),
      );

      expect(key.currentState!.validate(), isNotNull);
    });
  });
}
