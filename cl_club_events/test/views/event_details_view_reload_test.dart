import 'package:cl_club_events/src/models/camp_event_form_helpers.dart'
    show EventFormSubmit;
import 'package:cl_club_events/src/views/event_details_view.dart';
import 'package:cl_club_events/src/widgets/events_preview/cl_event_enrolments_summary.dart';
import 'package:cl_club_events/src/widgets/events_preview/cl_event_pending_requests.dart';
import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/credit_scope.dart';

/// How long an enrolment read takes: long enough for a frame to show a
/// loading view if one is shown.
const _readTime = Duration(milliseconds: 200);

/// An events master that saves an event in place, as the real one does
/// with the server's answer: it stores the event and bumps the occurrence
/// version (which every event save still does).
class _SavingEvents extends ClEventsMasterNotifier {
  _SavingEvents(this.events);
  final Map<int, Event> events;

  @override
  Future<Map<int, Event>> build() async => events;

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
    final current = state.requireValue[eventId]!;
    final updated = current.copyWith(
      version: current.version + 1,
      description: description,
      visibility: visibility,
      isFeatured: isFeatured,
      // A server answer carries new lists.
      coachNames: () =>
          current.coachNames == null ? null : [...current.coachNames!],
    );
    replaceLocally(updated);
    bumpOccurrencesVersion();
    return updated;
  }
}

/// The real enrolment master, with a slow read that counts itself.
class _SlowEnrollments extends ClEnrollmentsMasterNotifier {
  static int reads = 0;

  @override
  Future<Map<String, EnrollmentStatus>> fetch() async {
    reads++;
    await Future<void>.delayed(_readTime);
    return {
      for (var i = 0; i < 4; i++) 'member_$i': EnrollmentStatus.accepted,
      for (var i = 0; i < 3; i++) 'asker_$i': EnrollmentStatus.requested,
    };
  }
}

/// The page's own vertical scroll.
ScrollPosition _pageScroll(WidgetTester tester) => tester
    .state<ScrollableState>(
      find
          .descendant(
            of: find.byType(EventDetailsView),
            matching: find.byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            ),
          )
          .first,
    )
    .position;

/// Whether any enrolment section shows its loading view.
bool _anySectionLoading() =>
    find
        .descendant(
          of: find.byType(ClEventPendingRequests),
          matching: find.byType(CircularProgressIndicator),
        )
        .evaluate()
        .isNotEmpty ||
    find
        .descendant(
          of: find.byType(ClEventEnrolmentsSummary),
          matching: find.byType(CircularProgressIndicator),
        )
        .evaluate()
        .isNotEmpty;

/// Pumps frames through one enrolment read, failing if any frame shows an
/// enrolment section loading or moves the page.
Future<void> _expectSteadyThroughARead(
  WidgetTester tester,
  double offset,
) async {
  for (var t = Duration.zero; t <= _readTime * 2; t += _readTime ~/ 4) {
    await tester.pump(_readTime ~/ 4);
    expect(_anySectionLoading(), isFalse, reason: 'a section loading at $t');
    expect(_pageScroll(tester).pixels, offset, reason: 'scroll moved at $t');
  }
}

void main() {
  testWidgets('Issue 230: toggling Private and saving another section keep '
      'the event page where it was, with no section loading', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    _SlowEnrollments.reads = 0;

    final admin = person('an_admin', admin: true);
    final events = _SavingEvents({campId: staffed(campId, EventType.camp)});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          creditSystemProvider.overrideWithValue(false),
          authStateProvider.overrideWith(() => StubAuth(admin)),
          clEventsMasterProvider.overrideWith(() => events),
          clEnrollmentsMasterProvider.overrideWith(_SlowEnrollments.new),
          clEventCreditRosterProvider.overrideWith(() => StubRoster(const {})),
          clCreditAccountsMasterProvider.overrideWith(
            () => StubAccounts(const {}),
          ),
          clUsableCreditAccountsProvider.overrideWith(
            () => StubUsableAccounts(const {}),
          ),
        ],
        child: ShadApp(
          home: Scaffold(
            body: EventDetailsView(currentUser: admin, eventId: campId),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(_readTime * 2);
    await tester.pump();
    expect(_anySectionLoading(), isFalse, reason: 'loaded');
    final readsOnOpen = _SlowEnrollments.reads;

    // Scroll down to the flags, with the enrolment sections below them.
    final privateBox = find.text('This is a private event');
    await tester.scrollUntilVisible(
      privateBox,
      200,
      scrollable: find
          .descendant(
            of: find.byType(EventDetailsView),
            matching: find.byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            ),
          )
          .first,
    );
    await tester.pump();
    final offset = _pageScroll(tester).pixels;
    expect(offset, greaterThan(0));

    await tester.tap(privateBox);
    await _expectSteadyThroughARead(tester, offset);
    expect(
      events.state.requireValue[campId]!.visibility,
      Visibility.private,
      reason: 'the toggle saved',
    );

    // Another section's save: the Overview card's description.
    await EventFormSubmit.updateDescription(
      event: events.state.requireValue[campId]!,
      description: 'New description',
      notifier: events,
    );
    await _expectSteadyThroughARead(tester, offset);

    expect(_SlowEnrollments.reads, readsOnOpen, reason: 'no enrolment read');
  });
}
