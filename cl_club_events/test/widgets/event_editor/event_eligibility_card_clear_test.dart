import 'package:cl_club_events/src/widgets/event_editor/event_eligibility_card.dart';
import 'package:cl_club_forms/cl_club_forms.dart' show EligibilityGender;
import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_form_fields.dart'
    show AgeEligibilityFormFields;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEventsMasterNotifier, clEventsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show SectionEditButton;

Event _event({
  EventType type = EventType.camp,
  List<Gender> genders = const [],
  Age? minAge,
  Age? maxAge,
  bool strictAge = false,
}) => Event(
  id: 1,
  version: 4,
  title: 'workflow_clear',
  description: '',
  type: type,
  visibility: Visibility.public,
  venueId: 7,
  startTimeUtc: DateTime.utc(2026, 6, 15, 6),
  endTimeUtc: DateTime.utc(2026, 6, 15, 8),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
  genders: genders,
  minAge: minAge,
  maxAge: maxAge,
  strictAge: strictAge,
);

/// What one eligibility write carried.
class _Sent {
  _Sent(
    this.verb, {
    required this.genders,
    required this.minAge,
    required this.maxAge,
    required this.strictAge,
  });
  final String verb;
  final List<Gender> Function()? genders;
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
    List<Gender> Function()? genders,
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
        genders: genders,
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
    List<Gender> Function()? genders,
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
        genders: genders,
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

/// The Strict age check's box.
Finder get _strictBox => find.descendant(
  of: find.byWidgetPredicate(
    (w) =>
        w is ShadCheckboxFormField &&
        w.id == AgeEligibilityFormFields.strictAgeId,
  ),
  matching: find.byType(ShadCheckbox),
);

/// The box of [gender].
Finder _genderBox(EligibilityGender gender) => find.byKey(ValueKey(gender));

bool _ticked(WidgetTester tester, Finder box) =>
    tester.widget<ShadCheckbox>(box).value;

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
  testWidgets('Issue 34: no Clear in read mode, nor in the editor of an '
      'event with no eligibility', (tester) async {
    await _pump(tester, _event());
    expect(find.text('Clear'), findsNothing);

    await _openEditor(tester);

    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Clear'), findsNothing);
  });

  testWidgets('Issue 34: Clear shows as soon as the editor opens on an '
      'event with a gender, an age or the Strict age check', (tester) async {
    for (final event in [
      _event(genders: const [Gender.female]),
      _event(minAge: const Age(years: 5)),
      _event(maxAge: const Age(years: 18)),
      _event(strictAge: true),
    ]) {
      await _pump(tester, event);
      expect(find.text('Clear'), findsNothing, reason: 'read mode');

      await _openEditor(tester);

      expect(find.text('Clear'), findsOneWidget, reason: '$event');
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('Issue 34: Clear appears once an age is typed and goes when '
      'it is emptied again', (tester) async {
    await _pump(tester, _event());
    await _openEditor(tester);
    expect(find.text('Clear'), findsNothing);

    await tester.enterText(_input(AgeEligibilityFormFields.minAgeYearsId), '5');
    await tester.pumpAndSettle();
    expect(find.text('Clear'), findsOneWidget);

    await tester.enterText(_input(AgeEligibilityFormFields.minAgeYearsId), '');
    await tester.pumpAndSettle();
    expect(find.text('Clear'), findsNothing);
  });

  testWidgets('Issue 34: Clear appears when only the Strict age check is '
      'ticked', (tester) async {
    await _pump(tester, _event());
    await _openEditor(tester);

    await tester.tap(_strictBox);
    await tester.pumpAndSettle();

    expect(find.text('Clear'), findsOneWidget);
  });

  testWidgets('Issue 34: pressing Clear empties the fields, hides the '
      'button and stores nothing', (tester) async {
    final events = await _pump(
      tester,
      _event(
        genders: const [Gender.female],
        minAge: const Age(years: 5),
        maxAge: const Age(years: 18),
        strictAge: true,
      ),
    );
    await _openEditor(tester);

    await _tap(tester, 'Clear');

    expect(find.text('Clear'), findsNothing);
    expect(find.text('Save'), findsOneWidget, reason: 'still editing');
    expect(_text(tester, AgeEligibilityFormFields.minAgeYearsId), isEmpty);
    expect(_text(tester, AgeEligibilityFormFields.maxAgeYearsId), isEmpty);
    expect(_ticked(tester, _strictBox), isFalse);
    for (final gender in EligibilityGender.values) {
      expect(_ticked(tester, _genderBox(gender)), isFalse, reason: '$gender');
    }
    expect(events.sent, isEmpty);
  });

  testWidgets('Issue 34: Save after Clear stores an event with no '
      'eligibility', (tester) async {
    final events = await _pump(
      tester,
      _event(
        genders: const [Gender.female],
        minAge: const Age(years: 5),
        maxAge: const Age(years: 18),
        strictAge: true,
      ),
    );
    await _openEditor(tester);
    await _tap(tester, 'Clear');

    await _tap(tester, 'Save');

    final sent = events.sent.single;
    expect(sent.verb, 'update');
    expect(sent.genders, isNotNull);
    expect(sent.genders!(), isEmpty);
    expect(sent.minAge!(), isNull);
    expect(sent.maxAge!(), isNull);
    expect(sent.strictAge, isFalse);
  });

  testWidgets("Issue 34: a programme's clear is saved as a correction", (
    tester,
  ) async {
    final events = await _pump(
      tester,
      _event(type: EventType.programme, maxAge: const Age(years: 12)),
    );
    await _openEditor(tester);
    await _tap(tester, 'Clear');

    await _tap(tester, 'Save');

    final sent = events.sent.single;
    expect(sent.verb, 'correction');
    // The programme had no gender and Clear leaves every box unticked:
    // unchanged, so it is not sent.
    expect(sent.genders, isNull);
    expect(sent.minAge!(), isNull);
    expect(sent.maxAge!(), isNull);
    expect(sent.strictAge, isFalse);
  });

  testWidgets('Issue 34: Cancel after Clear stores nothing and the editor '
      'reopens on the old values', (tester) async {
    final events = await _pump(
      tester,
      _event(minAge: const Age(years: 5), maxAge: const Age(years: 18)),
    );
    await _openEditor(tester);
    await _tap(tester, 'Clear');

    await _tap(tester, 'Cancel');

    expect(events.sent, isEmpty);
    expect(find.text('Open to members aged 5 to 18.'), findsOneWidget);

    await _openEditor(tester);

    expect(_text(tester, AgeEligibilityFormFields.minAgeYearsId), '5');
    expect(_text(tester, AgeEligibilityFormFields.maxAgeYearsId), '18');
    expect(find.text('Clear'), findsOneWidget);
  });

  testWidgets('Issue 80: the editor offers the four gender boxes; ticking '
      'Boys, Other and Prefer not to say saves exactly those three and the '
      'read view names them', (tester) async {
    final events = await _pump(tester, _event());
    await _openEditor(tester);

    for (final label in ['Boys', 'Girls', 'Other', 'Prefer not to say']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(
      find.text('No box ticked: open to members of every gender.'),
      findsOneWidget,
    );

    for (final gender in [
      EligibilityGender.boys,
      EligibilityGender.other,
      EligibilityGender.preferNotToSay,
    ]) {
      await tester.tap(_genderBox(gender));
      await tester.pumpAndSettle();
    }
    expect(
      find.text('No box ticked: open to members of every gender.'),
      findsNothing,
    );
    await _tap(tester, 'Save');

    expect(events.sent.single.genders!(), [
      Gender.male,
      Gender.other,
      Gender.preferNotToSay,
    ]);
  });

  testWidgets('Issue 80: the editor opens with the stored genders ticked; '
      'unticking them all saves no gender criterion', (tester) async {
    final events = await _pump(
      tester,
      _event(genders: const [Gender.female, Gender.other]),
    );
    expect(find.text('This event is for Girls and Other.'), findsOneWidget);
    await _openEditor(tester);

    expect(_ticked(tester, _genderBox(EligibilityGender.girls)), isTrue);
    expect(_ticked(tester, _genderBox(EligibilityGender.other)), isTrue);
    expect(_ticked(tester, _genderBox(EligibilityGender.boys)), isFalse);

    await tester.tap(_genderBox(EligibilityGender.girls));
    await tester.pumpAndSettle();
    await tester.tap(_genderBox(EligibilityGender.other));
    await tester.pumpAndSettle();
    await _tap(tester, 'Save');

    expect(events.sent.single.genders!(), isEmpty);
  });

  testWidgets('Issue 80: a box ticked and unticked again does not send '
      'the genders', (tester) async {
    final events = await _pump(
      tester,
      _event(genders: const [Gender.male], maxAge: const Age(years: 12)),
    );
    await _openEditor(tester);

    await tester.tap(_genderBox(EligibilityGender.girls));
    await tester.pumpAndSettle();
    await tester.tap(_genderBox(EligibilityGender.girls));
    await tester.pumpAndSettle();
    await tester.enterText(
      _input(AgeEligibilityFormFields.maxAgeYearsId),
      '14',
    );
    await tester.pumpAndSettle();
    await _tap(tester, 'Save');

    final sent = events.sent.single;
    expect(sent.genders, isNull);
    expect(sent.maxAge!(), const Age(years: 14));
  });

  testWidgets('Issue 80: a box ticked and unticked again, then Save, sends '
      'nothing', (tester) async {
    final events = await _pump(
      tester,
      _event(genders: const [Gender.male], maxAge: const Age(years: 12)),
    );
    await _openEditor(tester);

    await tester.tap(_genderBox(EligibilityGender.girls));
    await tester.pumpAndSettle();
    await tester.tap(_genderBox(EligibilityGender.girls));
    await tester.pumpAndSettle();
    await _tap(tester, 'Save');

    expect(events.sent, isEmpty);
  });
}
