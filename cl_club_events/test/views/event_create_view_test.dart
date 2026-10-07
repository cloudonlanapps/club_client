import 'package:cl_club_events/src/utils/event_create_error.dart';
import 'package:cl_club_events/src/views/event_create_view.dart';
import 'package:cl_club_forms/cl_club_forms.dart'
    show
        EventCreateForm,
        EventCreateFormFields,
        EventCreateFormState,
        EventFormType;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEventsMasterNotifier, clEventsMasterProvider, clVenuesProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const String _rawServerText = 'raw server text';

/// An events master that records the creates sent to it, or refuses them
/// with [error]. It never reaches a server.
class _RecordingEvents extends ClEventsMasterNotifier {
  final List<String> created = [];
  Exception? error;

  @override
  Future<Map<int, Event>> build() async => const {};

  @override
  Future<Event> createEvent({
    required String title,
    required String description,
    required EventType type,
    required Visibility visibility,
    required int venueId,
    required DateTime startTimeUtc,
    required DateTime endTimeUtc,
    String? organizerName,
    List<String>? coachNames,
    String? rrule,
    Gender? gender,
    Age? minAge,
    Age? maxAge,
    bool? strictAge,
    bool isFeatured = false,
    List<String>? galleryUris,
    List<EventSession>? sessions,
  }) async {
    final refusal = error;
    if (refusal != null) throw refusal;
    created.add(title);
    return Event(
      id: 1,
      version: 1,
      title: title,
      description: description,
      type: type,
      visibility: visibility,
      venueId: venueId,
      startTimeUtc: startTimeUtc,
      endTimeUtc: endTimeUtc,
      createdAtUtc: DateTime.utc(2026),
      updatedAtUtc: DateTime.utc(2026),
    );
  }
}

ServerException _refusal(String code) =>
    ServerException(statusCode: 422, code: code, message: _rawServerText);

class _Host {
  _Host(this.events);

  final _RecordingEvents events;
  int createdCalls = 0;
}

Future<_Host> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final host = _Host(_RecordingEvents());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clEventsMasterProvider.overrideWith(() => host.events),
        clVenuesProvider.overrideWith(
          (ref, key) async => [
            Venue(
              id: 7,
              name: 'North Rink',
              createdAtUtc: DateTime.utc(2026),
              updatedAtUtc: DateTime.utc(2026),
            ),
          ],
        ),
      ],
      child: ShadApp(
        home: Scaffold(
          body: EventCreateView(
            eventType: EventFormType.oneOff,
            onCreated: () => host.createdCalls++,
            onCancel: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return host;
}

EventCreateFormState _form(WidgetTester tester) =>
    tester.state<EventCreateFormState>(find.byType(EventCreateForm));

/// Fills the title and picks the venue, so the form is valid.
Future<void> _fill(WidgetTester tester) async {
  _form(tester).formKey.currentState!
    ..setFieldValue<String>(EventCreateFormFields.titleId, 'Open day')
    ..setFieldValue<int>(EventCreateFormFields.venueId, 7);
  await tester.pumpAndSettle();
}

Future<void> _create(WidgetTester tester) async {
  await tester.tap(find.text('Create one-off'));
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 54: the create view drives EventCreateForm', () {
    testWidgets('Issue 54: the view owns the title and the Create button', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('New One-off'), findsOneWidget);
      expect(find.text('Create one-off'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(EventCreateForm),
          matching: find.byType(ShadButton),
        ),
        findsNothing,
      );
    });

    testWidgets('Issue 54: Create validates the form before anything is sent', (
      tester,
    ) async {
      final host = await _pump(tester);

      await _create(tester);

      expect(find.text('Title is required'), findsOneWidget);
      expect(host.events.created, isEmpty);
      expect(host.createdCalls, 0);
    });

    testWidgets('Issue 54: a valid form is created and the view moves on', (
      tester,
    ) async {
      final host = await _pump(tester);
      await _fill(tester);

      await _create(tester);

      expect(host.events.created, ['Open day']);
      expect(host.createdCalls, 1);
      expect(find.text('One-off "Open day" created.'), findsOneWidget);
    });

    testWidgets('Issue 54: a venue the server refuses shows on the venue and '
        'the form stays open for another try', (tester) async {
      final host = await _pump(tester);
      await _fill(tester);
      host.events.error = _refusal(SdkErrorCode.venueNotFound);

      await _create(tester);

      expect(
        find.descendant(
          of: find.byType(EventCreateForm),
          matching: find.textContaining('That venue no longer exists'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining(_rawServerText), findsNothing);
      expect(host.createdCalls, 0);

      host.events.error = null;
      await _create(tester);
      expect(host.events.created, ['Open day']);
      expect(host.createdCalls, 1);
    });

    testWidgets('Issue 54: a clash shows inline in the form', (tester) async {
      final host = await _pump(tester);
      await _fill(tester);
      host.events.error = _refusal(SdkErrorCode.timeConflict);

      await _create(tester);

      expect(
        find.descendant(
          of: find.byType(EventCreateForm),
          matching: find.textContaining('clashes with another booking'),
        ),
        findsOneWidget,
      );
      expect(host.createdCalls, 0);
    });

    testWidgets('Issue 54: any other failure is the fixed toast, outside the '
        'form', (tester) async {
      final host = await _pump(tester);
      await _fill(tester);
      host.events.error = _refusal('SOMETHING_ELSE');

      await _create(tester);

      expect(
        find.text('Could not create one-off. Please try again.'),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(EventCreateForm),
          matching: find.textContaining('Could not create'),
        ),
        findsNothing,
      );
      expect(find.textContaining(_rawServerText), findsNothing);
    });
  });

  group('Issue 54: eventCreateRefusal', () {
    const fallback = 'Could not create one-off. Please try again.';

    test('Issue 54: names the field a refusal is about', () {
      expect(
        eventCreateRefusal(
          _refusal(SdkErrorCode.venueNotFound),
          fallback: fallback,
        )?.fieldErrors.keys,
        [EventCreateFormFields.venueId],
      );
      for (final code in [
        SdkErrorCode.beyondSchedulingHorizon,
        SdkErrorCode.invalidSessionsTotal,
      ]) {
        expect(
          eventCreateRefusal(
            _refusal(code),
            fallback: fallback,
          )?.fieldErrors.keys,
          [EventCreateFormFields.scheduleId],
          reason: code,
        );
      }
    });

    test('Issue 54: a clash is a form-level message, anything else none', () {
      final clash = eventCreateRefusal(
        _refusal(SdkErrorCode.conflict),
        fallback: fallback,
      );
      expect(clash?.fieldErrors, isEmpty);
      expect(clash?.formError, isNotNull);
      expect(
        eventCreateRefusal(_refusal('SOMETHING_ELSE'), fallback: fallback),
        isNull,
      );
      expect(eventCreateRefusal(StateError('x'), fallback: fallback), isNull);
    });
  });
}
