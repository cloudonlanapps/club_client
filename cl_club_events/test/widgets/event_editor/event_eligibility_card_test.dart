import 'package:cl_club_events/src/widgets/event_editor/event_eligibility_card.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEventsMasterNotifier, clEventsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/age_eligibility/age_eligibility_fields.dart'
    show AgeEligibilityFields;
import 'package:ui_lib/src/widgets/age_eligibility/age_eligibility_form_fields.dart'
    show AgeEligibilityFormFields;
import 'package:ui_lib/src/widgets/age_eligibility/age_eligibility_form_validators.dart'
    show AgeEligibilityFormValidators;
import 'package:ui_lib/ui_lib.dart' show SectionEditButton;

Event _event({
  EventType type = EventType.camp,
  Age? minAge,
  Age? maxAge,
  bool strictAge = false,
  DateTime? dobOnOrAfterUtc,
  DateTime? dobOnOrBeforeUtc,
  DateTime? eligibilityReferenceDayUtc,
}) => Event(
  id: 1,
  version: 4,
  title: 'workflow_age',
  description: '',
  type: type,
  visibility: Visibility.public,
  venueId: 7,
  startTimeUtc: DateTime.utc(2026, 6, 15, 6),
  endTimeUtc: DateTime.utc(2026, 6, 15, 8),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
  minAge: minAge,
  maxAge: maxAge,
  strictAge: strictAge,
  dobOnOrAfterUtc: dobOnOrAfterUtc,
  dobOnOrBeforeUtc: dobOnOrBeforeUtc,
  eligibilityReferenceDayUtc: eligibilityReferenceDayUtc,
);

/// What one eligibility write carried.
class _Sent {
  _Sent(this.verb, this.minAge, this.maxAge, {required this.strictAge});
  final String verb;
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
    sent.add(_Sent('update', minAge, maxAge, strictAge: strictAge));
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
    sent.add(_Sent('correction', minAge, maxAge, strictAge: strictAge));
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

Future<void> _openEditor(WidgetTester tester) async {
  await tester.tap(find.byType(SectionEditButton));
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Issue 33: the read view shows the age sentence with the '
      "server's dates and reference day beneath", (tester) async {
    await _pump(
      tester,
      _event(
        minAge: const Age(years: 5),
        maxAge: const Age(years: 18),
        dobOnOrAfterUtc: DateTime.utc(2007, 6, 16),
        dobOnOrBeforeUtc: DateTime.utc(2022, 6, 14),
        eligibilityReferenceDayUtc: DateTime.utc(2026, 6, 15),
      ),
    );

    expect(find.text('Open to members aged 5 to 18.'), findsOneWidget);
    expect(
      find.text('Born 16 Jun 2007 – 14 Jun 2022, counted on 15 Jun 2026.'),
      findsOneWidget,
    );
  });

  testWidgets('Issue 33: the editor shows the age inputs and the Strict age '
      'check, and no date pickers', (tester) async {
    await _pump(tester, _event());
    expect(find.text('This event is open to all.'), findsOneWidget);

    await _openEditor(tester);

    expect(find.text(AgeEligibilityFields.minAgeTitle), findsOneWidget);
    expect(find.text(AgeEligibilityFields.maxAgeTitle), findsOneWidget);
    expect(find.text(AgeEligibilityFields.strictLabel), findsOneWidget);
    expect(find.textContaining('DOB'), findsNothing);
  });

  testWidgets('Issue 33: saving 5 and 18 years with Strict age check sends '
      'minAge, maxAge and strictAge', (tester) async {
    final events = await _pump(tester, _event());
    await _openEditor(tester);

    await tester.enterText(_input(AgeEligibilityFormFields.minAgeYearsId), '5');
    await tester.enterText(
      _input(AgeEligibilityFormFields.maxAgeYearsId),
      '18',
    );
    await tester.tap(find.byType(ShadCheckbox));
    await tester.pumpAndSettle();
    await _save(tester);

    final sent = events.sent.single;
    expect(sent.verb, 'update');
    expect(sent.minAge!(), const Age(years: 5));
    expect(sent.maxAge!(), const Age(years: 18));
    expect(sent.strictAge, isTrue);
  });

  testWidgets('Issue 33: emptying an age clears that bound', (tester) async {
    final events = await _pump(
      tester,
      _event(minAge: const Age(years: 5), maxAge: const Age(years: 18)),
    );
    await _openEditor(tester);

    await tester.enterText(_input(AgeEligibilityFormFields.minAgeYearsId), '');
    await tester.pumpAndSettle();
    await _save(tester);

    final sent = events.sent.single;
    expect(sent.minAge!(), isNull);
    expect(sent.maxAge!(), const Age(years: 18));
  });

  testWidgets('Issue 33: a minimum above the maximum shows the inline '
      'message and does not save', (tester) async {
    final events = await _pump(tester, _event());
    await _openEditor(tester);

    await tester.enterText(
      _input(AgeEligibilityFormFields.minAgeYearsId),
      '18',
    );
    await tester.enterText(_input(AgeEligibilityFormFields.maxAgeYearsId), '5');
    await tester.pumpAndSettle();
    await _save(tester);

    expect(find.text(AgeEligibilityFormValidators.bandMessage), findsOneWidget);
    expect(events.sent, isEmpty);
    expect(find.text('Save'), findsOneWidget, reason: 'still editing');
  });

  testWidgets("Issue 33: a programme's ages are saved as a correction", (
    tester,
  ) async {
    final events = await _pump(tester, _event(type: EventType.programme));
    await _openEditor(tester);

    await tester.enterText(
      _input(AgeEligibilityFormFields.maxAgeYearsId),
      '12',
    );
    await tester.pumpAndSettle();
    await _save(tester);

    final sent = events.sent.single;
    expect(sent.verb, 'correction');
    expect(sent.minAge!(), isNull);
    expect(sent.maxAge!(), const Age(years: 12));
    expect(sent.strictAge, isFalse);
  });
}
