// Event create flows for integration tests.
//
// Owns:
//   * createEventViaUi — opens the staff list for a type (camps or
//     programmes), taps "+ New …", fills title + venue (+ an optional
//     schedule set straight into the form), submits, and waits for the form
//     to close.
//   * waitForEvent / waitForVenueId — read the masters the mounted tree
//     watches until the created row appears.

import 'package:cl_club_forms/src/widgets/event_schedule/weekday_selector.dart'
    show WeekdayChip;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventsMasterProvider, clVenuesMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show Event, EventType;
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ActionButton, ActionIcon;

import 'auth.dart';
import 'forms.dart';
import 'pump.dart';

/// The staff list path, create button and submit label for [type].
({String path, String create, String submit}) _eventTypeUi(EventType type) =>
    switch (type) {
      EventType.camp => (
        path: '/memberzone/events/camps',
        create: '+ New Camp',
        submit: 'Create camp',
      ),
      EventType.programme => (
        path: '/memberzone/events/programmes',
        create: '+ New Programme',
        submit: 'Create programme',
      ),
      EventType.oneOff => (
        path: '/memberzone/events/one-off',
        create: '+ New One-off',
        submit: 'Create one-off',
      ),
    };

/// Navigate to the staff list for [type], open "+ New …", fill the title and
/// venue, tap [weekdays] (1 = Monday) on a programme's day chips, and submit.
/// The schedule's dates and times keep the form's seeded defaults.
Future<void> createEventViaUi(
  WidgetTester tester, {
  required EventType type,
  required String title,
  required int venueId,
  Set<int> weekdays = const {},
}) async {
  final ui = _eventTypeUi(type);
  await go(tester, ui.path);
  await waitFor(
    tester,
    () =>
        find.widgetWithText(ActionButton, ui.create).evaluate().isNotEmpty ||
        find
            .byWidgetPredicate((w) => w is ActionIcon && w.icon == Icons.add)
            .evaluate()
            .isNotEmpty,
    description: 'create affordance on ${ui.path}',
  );
  final wideButton = find.widgetWithText(ActionButton, ui.create);
  if (wideButton.evaluate().isNotEmpty) {
    tester.widget<ActionButton>(wideButton).onPressed!.call();
  } else {
    final narrowIcon = find.byWidgetPredicate(
      (w) => w is ActionIcon && w.icon == Icons.add,
    );
    tester.widget<ActionIcon>(narrowIcon).onPressed!.call();
  }
  await settle(tester);

  await waitFor(
    tester,
    () => find
        .byWidgetPredicate((w) => w is ShadInputFormField && w.id == 'title')
        .evaluate()
        .isNotEmpty,
    description: '${type.name} create form to mount',
  );

  await enterTextById(tester, 'title', title);
  // The venue ShadSelect is set straight into the form's value map (driving
  // the overlay is fragile).
  setShadFormValues(tester, {'venue': venueId});
  await tester.pump();
  // The schedule's inner fields keep their own state, so the days are
  // picked on the chips as a user does.
  final chips = find.byType(WeekdayChip);
  for (final day in weekdays) {
    tester.widget<WeekdayChip>(chips.at(day - 1)).onTap();
    await tester.pump();
  }

  final submit = find.widgetWithText(ShadButton, ui.submit);
  await waitFor(
    tester,
    () => submit.evaluate().isNotEmpty,
    description: '"${ui.submit}" submit button',
  );
  final btn = tester.widget<ShadButton>(submit);
  expect(
    btn.onPressed,
    isNotNull,
    reason: '"${ui.submit}" button should be enabled before submit',
  );
  btn.onPressed!.call();
  await settle(tester);

  await waitFor(
    tester,
    () {
      final toast = firstErrorToastMessage(tester);
      if (toast != null) {
        throw TestFailure(
          '${type.name} create form rejected "$title". Toast: "$toast"',
        );
      }
      return find.widgetWithText(ShadButton, ui.submit).evaluate().isEmpty;
    },
    description: '${type.name} create form to close after creating "$title"',
  );
}

/// Waits until the venue named [name] is in the venues master; returns its id.
Future<int> waitForVenueId(WidgetTester tester, String name) async {
  await waitFor(
    tester,
    () {
      final map = container(tester).read(clVenuesMasterProvider).valueOrNull;
      return map != null && map.values.any((v) => v.name == name);
    },
    description: 'clVenuesMasterProvider to contain "$name"',
  );
  final map = container(tester).read(clVenuesMasterProvider).valueOrNull!;
  return map.values.firstWhere((v) => v.name == name).id;
}

/// Waits until an event titled [title] is in the events master; returns it.
Future<Event> waitForEvent(WidgetTester tester, String title) async {
  await waitFor(
    tester,
    () {
      final map = container(tester).read(clEventsMasterProvider).valueOrNull;
      return map != null && map.values.any((e) => e.title == title);
    },
    description: 'clEventsMasterProvider to contain "$title"',
  );
  final map = container(tester).read(clEventsMasterProvider).valueOrNull!;
  return map.values.firstWhere((e) => e.title == title);
}
