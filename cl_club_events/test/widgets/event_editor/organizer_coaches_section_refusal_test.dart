// Issue 97: the Organizer & Coaches editor shows a refused save where it
// belongs: on the organizer or the coaches the server no longer knows,
// inline for a clash, and in a toast for a failure that is not about them.
import 'dart:async';

import 'package:cl_club_events/src/models/camp_event_form_helpers.dart'
    show EventFormSubmit;
import 'package:cl_club_events/src/widgets/event_editor/editable_event_body.dart'
    show OrganizerCoachesSection;
import 'package:cl_club_forms/cl_club_forms.dart'
    show EventFormFields, EventStaffForm;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        ClEventsMasterNotifier,
        ClUsersMasterNotifier,
        clEventsMasterProvider,
        clUsersMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

final Event _event = Event(
  id: 1,
  version: 4,
  title: 'workflow_staff',
  description: '',
  type: EventType.camp,
  visibility: Visibility.public,
  venueId: 7,
  startTimeUtc: DateTime.utc(2026, 6, 15, 6),
  endTimeUtc: DateTime.utc(2026, 6, 15, 8),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
  organizerName: 'org',
  coachNames: const ['coach_a'],
);

/// Fails every update with [failure].
class _FailingEvents extends ClEventsMasterNotifier {
  _FailingEvents(this.failure);

  final Exception failure;

  @override
  Future<Map<int, Event>> build() async => {_event.id: _event};

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
  }) async => throw failure;
}

class _NoUsers extends ClUsersMasterNotifier {
  @override
  Future<Map<String, UserInfo>> build() async => {};
}

Finder _field(String id) =>
    find.byWidgetPredicate((w) => w is ShadFormBuilderField && w.id == id);

/// Opens the editor, removes the one coach and saves, the save failing
/// with [failure].
Future<void> _saveFailing(WidgetTester tester, Exception failure) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clEventsMasterProvider.overrideWith(() => _FailingEvents(failure)),
        clUsersMasterProvider.overrideWith(_NoUsers.new),
      ],
      child: ShadApp(
        home: ShadToaster(
          child: Scaffold(
            body: SingleChildScrollView(
              child: OrganizerCoachesSection(event: _event),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(LucideIcons.pencil));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithIcon(ShadButton, LucideIcons.x));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ShadButton, 'Save'));
  await tester.pumpAndSettle();
}

ServerException _refused(String code, int status, String message) =>
    ServerException(statusCode: status, code: code, message: message);

void _expectEditorOn(WidgetTester tester) {
  expect(
    tester.widget<EventStaffForm>(find.byType(EventStaffForm)).enabled,
    isTrue,
  );
  expect(
    tester
        .widget<ShadButton>(find.widgetWithText(ShadButton, 'Save'))
        .onPressed,
    isNotNull,
  );
}

void main() {
  group('Issue 97: the Organizer & Coaches editor shows a refusal where it '
      'belongs', () {
    testWidgets('Issue 97: an organizer the server no longer knows shows on '
        'the organizer, with no toast', (tester) async {
      await _saveFailing(
        tester,
        _refused(SdkErrorCode.userNotFound, 404, 'Organizer not found'),
      );

      expect(
        find.descendant(
          of: _field(EventFormFields.organizerNameId),
          matching: find.text(EventFormSubmit.organizerGoneMessage),
        ),
        findsOneWidget,
      );
      expect(find.byType(ShadToast), findsNothing);
      expect(find.textContaining('not found'), findsNothing);
      _expectEditorOn(tester);
    });

    testWidgets('Issue 97: a coach the server no longer knows shows on the '
        'coaches, with no toast', (tester) async {
      await _saveFailing(
        tester,
        _refused(SdkErrorCode.userNotFound, 404, 'Coach not found: coach_b'),
      );

      expect(
        find.descendant(
          of: _field(EventFormFields.coachNamesId),
          matching: find.text(EventFormSubmit.coachGoneMessage),
        ),
        findsOneWidget,
      );
      expect(find.byType(ShadToast), findsNothing);
      _expectEditorOn(tester);
    });

    testWidgets('Issue 97: a clash with another booking shows inline in the '
        'form', (tester) async {
      await _saveFailing(
        tester,
        _refused(SdkErrorCode.timeConflict, 409, 'raw server text'),
      );

      expect(
        find.descendant(
          of: find.byType(EventStaffForm),
          matching: find.text(EventFormSubmit.staffClashMessage),
        ),
        findsOneWidget,
      );
      expect(find.byType(ShadToast), findsNothing);
      expect(find.textContaining('raw server text'), findsNothing);
    });

    testWidgets('Issue 97: a server that cannot be reached is a toast, and '
        'the editor is on again', (tester) async {
      await _saveFailing(tester, TimeoutException('connection closed'));

      expect(find.byType(ShadToast), findsOneWidget);
      expect(
        find.text(
          'Could not reach the server. Check the connection and try again.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('connection closed'), findsNothing);
      _expectEditorOn(tester);
    });

    testWidgets('Issue 97: a signed-in account that is gone is not the '
        'organizer: it is a toast', (tester) async {
      await _saveFailing(
        tester,
        _refused(SdkErrorCode.userNotFound, 401, 'User not found'),
      );

      expect(find.byType(ShadToast), findsOneWidget);
      expect(find.text(EventFormSubmit.organizerGoneMessage), findsNothing);
      expect(find.text(EventFormSubmit.coachGoneMessage), findsNothing);
    });
  });
}
