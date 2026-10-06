import 'package:cl_club_events/src/widgets/event_editor/event_eligibility_card.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEventsMasterNotifier, clEventsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show AgeEligibilityFormFields, SectionEditButton;

Event _event({
  EventType type = EventType.camp,
  Gender? gender,
  Age? minAge,
  Age? maxAge,
  bool strictAge = false,
}) => Event(
  id: 1,
  version: 4,
  title: 'workflow_reset',
  description: '',
  type: type,
  visibility: Visibility.public,
  venueId: 7,
  startTimeUtc: DateTime.utc(2026, 6, 15, 6),
  endTimeUtc: DateTime.utc(2026, 6, 15, 8),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
  gender: gender,
  minAge: minAge,
  maxAge: maxAge,
  strictAge: strictAge,
);

/// What one eligibility write carried.
class _Sent {
  _Sent(
    this.verb, {
    required this.gender,
    required this.minAge,
    required this.maxAge,
    required this.strictAge,
  });
  final String verb;
  final Gender? Function()? gender;
  final Age? Function()? minAge;
  final Age? Function()? maxAge;
  final bool? strictAge;
}

/// Records the eligibility writes the card sends.
class _RecordingEvents extends ClEventsMasterNotifier {
  _RecordingEvents(this.event);

  final Event event;
  final List<_Sent> sent = [];

  @override
  Future<Map<int, Event>> build() async => {event.id: event};

  @override
  Future<Event> updateEvent(
    int eventId, {
    int? version,
    String? title,
    String? description,
    Visibility? visibility,
    String? organizerName,
    List<String>? Function()? coachNames,
    Gender? Function()? gender,
    Age? Function()? minAge,
    Age? Function()? maxAge,
    bool? strictAge,
    bool? isFeatured,
    List<String>? Function()? galleryUris,
    List<EventSession>? Function()? sessions,
  }) async {
    sent.add(
      _Sent(
        'update',
        gender: gender,
        minAge: minAge,
        maxAge: maxAge,
        strictAge: strictAge,
      ),
    );
    return event;
  }

  @override
  Future<Event> correctionOnEvent(
    int eventId, {
    int? version,
    String? title,
    String? description,
    Visibility? visibility,
    Gender? Function()? gender,
    Age? Function()? minAge,
    Age? Function()? maxAge,
    bool? strictAge,
    bool? isFeatured,
    List<String>? Function()? galleryUris,
    List<EventSession>? Function()? sessions,
    int? scheduleId,
  }) async {
    sent.add(
      _Sent(
        'correction',
        gender: gender,
        minAge: minAge,
        maxAge: maxAge,
        strictAge: strictAge,
      ),
    );
    return event;
  }
}

Future<_RecordingEvents> _pump(WidgetTester tester, Event event) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final events = _RecordingEvents(event);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [clEventsMasterProvider.overrideWith(() => events)],
      child: ShadApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: EventEligibilityCard(event: event),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return events;
}

Finder _input(String id) => find.byWidgetPredicate(
  (w) => w is ShadInputFormField && w.id == id,
);

String _text(WidgetTester tester, String id) => tester
    .widget<EditableText>(
      find.descendant(of: _input(id), matching: find.byType(EditableText)),
    )
    .controller
    .text;

Future<void> _openEditor(WidgetTester tester) async {
  await tester.tap(find.byType(SectionEditButton));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Issue 34: no Reset in read mode, nor in the editor of an '
      'event with no eligibility', (tester) async {
    await _pump(tester, _event());
    expect(find.text('Reset'), findsNothing);

    await _openEditor(tester);

    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Reset'), findsNothing);
  });

  testWidgets('Issue 34: Reset shows as soon as the editor opens on an '
      'event with a gender, an age or the Strict age check', (tester) async {
    for (final event in [
      _event(gender: Gender.female),
      _event(minAge: const Age(years: 5)),
      _event(maxAge: const Age(years: 18)),
      _event(strictAge: true),
    ]) {
      await _pump(tester, event);
      expect(find.text('Reset'), findsNothing, reason: 'read mode');

      await _openEditor(tester);

      expect(find.text('Reset'), findsOneWidget, reason: '$event');
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('Issue 34: Reset appears once an age is typed and goes when '
      'it is emptied again', (tester) async {
    await _pump(tester, _event());
    await _openEditor(tester);
    expect(find.text('Reset'), findsNothing);

    await tester.enterText(_input(AgeEligibilityFormFields.minAgeYearsId), '5');
    await tester.pumpAndSettle();
    expect(find.text('Reset'), findsOneWidget);

    await tester.enterText(_input(AgeEligibilityFormFields.minAgeYearsId), '');
    await tester.pumpAndSettle();
    expect(find.text('Reset'), findsNothing);
  });

  testWidgets('Issue 34: Reset appears when only the Strict age check is '
      'ticked', (tester) async {
    await _pump(tester, _event());
    await _openEditor(tester);

    await tester.tap(find.byType(ShadCheckbox));
    await tester.pumpAndSettle();

    expect(find.text('Reset'), findsOneWidget);
  });

  testWidgets('Issue 34: pressing Reset empties the fields, hides the '
      'button and stores nothing', (tester) async {
    final events = await _pump(
      tester,
      _event(
        gender: Gender.female,
        minAge: const Age(years: 5),
        maxAge: const Age(years: 18),
        strictAge: true,
      ),
    );
    await _openEditor(tester);

    await _tap(tester, 'Reset');

    expect(find.text('Reset'), findsNothing);
    expect(find.text('Save'), findsOneWidget, reason: 'still editing');
    expect(_text(tester, AgeEligibilityFormFields.minAgeYearsId), isEmpty);
    expect(_text(tester, AgeEligibilityFormFields.maxAgeYearsId), isEmpty);
    expect(tester.widget<ShadCheckbox>(find.byType(ShadCheckbox)).value, false);
    expect(find.text('Any gender'), findsOneWidget);
    expect(events.sent, isEmpty);
  });

  testWidgets('Issue 34: Save after Reset stores an event with no '
      'eligibility', (tester) async {
    final events = await _pump(
      tester,
      _event(
        gender: Gender.female,
        minAge: const Age(years: 5),
        maxAge: const Age(years: 18),
        strictAge: true,
      ),
    );
    await _openEditor(tester);
    await _tap(tester, 'Reset');

    await _tap(tester, 'Save');

    final sent = events.sent.single;
    expect(sent.verb, 'update');
    expect(sent.gender, isNotNull);
    expect(sent.gender!(), isNull);
    expect(sent.minAge!(), isNull);
    expect(sent.maxAge!(), isNull);
    expect(sent.strictAge, isFalse);
  });

  testWidgets("Issue 34: a programme's reset is saved as a correction", (
    tester,
  ) async {
    final events = await _pump(
      tester,
      _event(type: EventType.programme, maxAge: const Age(years: 12)),
    );
    await _openEditor(tester);
    await _tap(tester, 'Reset');

    await _tap(tester, 'Save');

    final sent = events.sent.single;
    expect(sent.verb, 'correction');
    expect(sent.gender!(), isNull);
    expect(sent.minAge!(), isNull);
    expect(sent.maxAge!(), isNull);
    expect(sent.strictAge, isFalse);
  });

  testWidgets('Issue 34: Cancel after Reset stores nothing and the editor '
      'reopens on the old values', (tester) async {
    final events = await _pump(
      tester,
      _event(minAge: const Age(years: 5), maxAge: const Age(years: 18)),
    );
    await _openEditor(tester);
    await _tap(tester, 'Reset');

    await _tap(tester, 'Cancel');

    expect(events.sent, isEmpty);
    expect(find.text('Open to members aged 5 to 18.'), findsOneWidget);

    await _openEditor(tester);

    expect(_text(tester, AgeEligibilityFormFields.minAgeYearsId), '5');
    expect(_text(tester, AgeEligibilityFormFields.maxAgeYearsId), '18');
    expect(find.text('Reset'), findsOneWidget);
  });
}
