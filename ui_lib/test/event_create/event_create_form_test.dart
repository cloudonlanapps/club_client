import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

Widget _wrap(Widget child) => ShadApp(
  home: Scaffold(
    body: SingleChildScrollView(child: child),
  ),
);

Future<void> _setSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1024, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

/// Initial values for a fresh form with a venue already selected, so submit
/// tests don't need to drive the venue `ShadSelect` overlay.
Map<String, dynamic> _withVenue(EventFormType type, int venueId) =>
    EventCreateForm.defaultValues(type)
      ..[EventCreateFormFields.venueId] = venueId;

const _venues = [
  EventVenueOption(id: 1, name: 'Main Rink'),
  EventVenueOption(id: 2, name: 'Practice Rink'),
];

Future<GlobalKey<EventCreateFormState>> _pump(
  WidgetTester tester, {
  required EventFormType type,
  Map<String, dynamic>? initialValues,
  Future<void> Function(Map<String, dynamic>)? onSubmit,
}) async {
  await _setSurface(tester);
  final key = GlobalKey<EventCreateFormState>();
  await tester.pumpWidget(
    _wrap(
      EventCreateForm(
        key: key,
        eventType: type,
        venues: _venues,
        initialValues: initialValues,
        onSubmit: onSubmit ?? (_) async {},
      ),
    ),
  );
  await tester.pumpAndSettle();
  return key;
}

void main() {
  group('EventCreateForm dirty tracking', () {
    for (final type in EventFormType.values) {
      testWidgets('Issue 702: a fresh ${type.name} create form is not dirty', (
        tester,
      ) async {
        final key = await _pump(tester, type: type);
        expect(key.currentState!.isDirty, isFalse);
      });
    }

    testWidgets('Issue 702: editing the title makes the form dirty, '
        'reverting clears it', (tester) async {
      final key = await _pump(tester, type: EventFormType.camp);
      expect(key.currentState!.isDirty, isFalse);

      await tester.enterText(find.byType(EditableText).first, 'Summer Camp');
      await tester.pumpAndSettle();
      expect(key.currentState!.isDirty, isTrue);

      await tester.enterText(find.byType(EditableText).first, '');
      await tester.pumpAndSettle();
      expect(key.currentState!.isDirty, isFalse);
    });
  });

  group('EventCreateForm validation', () {
    testWidgets('Issue 702: empty title blocks submit', (tester) async {
      var submitted = false;
      final key = await _pump(
        tester,
        type: EventFormType.camp,
        initialValues: _withVenue(EventFormType.camp, 1),
        onSubmit: (_) async => submitted = true,
      );

      await key.currentState!.handleSubmit();
      await tester.pumpAndSettle();

      expect(submitted, isFalse);
      expect(find.text('Title is required'), findsOneWidget);
    });

    testWidgets('Issue 702: missing venue surfaces an inline error and '
        'blocks submit', (tester) async {
      var submitted = false;
      final initial = EventCreateForm.defaultValues(EventFormType.camp)
        ..[EventCreateFormFields.titleId] = 'Summer Camp';
      final key = await _pump(
        tester,
        type: EventFormType.camp,
        initialValues: initial,
        onSubmit: (_) async => submitted = true,
      );

      await key.currentState!.handleSubmit();
      await tester.pumpAndSettle();

      expect(submitted, isFalse);
      expect(find.text('Please select a venue'), findsOneWidget);
    });

    testWidgets('Issue 702: a valid camp submits the flat form values', (
      tester,
    ) async {
      Map<String, dynamic>? submitted;
      final initial = _withVenue(EventFormType.camp, 2)
        ..[EventCreateFormFields.titleId] = 'Summer Camp';
      final key = await _pump(
        tester,
        type: EventFormType.camp,
        initialValues: initial,
        onSubmit: (values) async => submitted = values,
      );

      await key.currentState!.handleSubmit();
      await tester.pumpAndSettle();

      expect(submitted, isNotNull);
      expect(submitted![EventCreateFormFields.titleId], 'Summer Camp');
      expect(submitted![EventCreateFormFields.venueId], 2);
      expect(
        submitted![EventCreateFormFields.visibilityId],
        EventFormVisibility.public,
      );
      expect(
        submitted![EventCreateFormFields.scheduleId],
        isA<CampScheduleData>(),
      );
    });
  });

  group('EventCreateFormValidators', () {
    test('Issue 702: title rejects blank, accepts non-blank', () {
      expect(EventCreateFormValidators.title(''), isNotNull);
      expect(EventCreateFormValidators.title('   '), isNotNull);
      expect(EventCreateFormValidators.title('Camp'), isNull);
    });

    test('Issue 702: venue rejects null, accepts an id', () {
      expect(EventCreateFormValidators.venue(null), isNotNull);
      expect(EventCreateFormValidators.venue(1), isNull);
    });
  });

  group('Issue 115: the programme default schedule', () {
    ProgrammeScheduleData schedule(DateTime now) =>
        EventCreateForm.defaultValues(
              EventFormType.programme,
              now: now,
            )[EventCreateFormFields.scheduleId]
            as ProgrammeScheduleData;

    test('Issue 115: starts at the next whole hour, today', () {
      final data = schedule(DateTime(2026, 9, 26, 10, 30));
      expect(data.startDate, DateTime(2026, 9, 26));
      expect(data.sessionStartTime?.hour, 11);
      expect(data.sessionStartTime?.minute, 0);
    });

    test('Issue 115: late in the evening it starts tomorrow, not at a '
        'midnight already past', () {
      final data = schedule(DateTime(2026, 9, 26, 23, 30));
      expect(data.startDate, DateTime(2026, 9, 27));
      expect(data.sessionStartTime?.hour, 0);
    });
  });
}
