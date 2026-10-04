import 'package:club_sdk_2/club_sdk_2.dart' show EventType;
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Pop the current route if there is one, otherwise navigate to [fallback].
///
/// Used by route callbacks that conceptually mean "I'm done here, take me
/// back". A blind `pop()` throws when the route was reached without a
/// `push()` (deep link, `go()`, cold-start), so callers fall back to the
/// route's parent URL.
void popOrGo(BuildContext context, String fallback) {
  final r = GoRouter.of(context);
  if (r.canPop()) {
    r.pop();
  } else {
    r.go(fallback);
  }
}

/// The staff list route for events of [type]; its create flow is `/new`
/// below it (club_core#115, #122).
String eventsListPath(EventType type) => switch (type) {
  EventType.programme => '/memberzone/events/programmes',
  EventType.camp => '/memberzone/events/camps',
  EventType.oneOff => '/memberzone/events/one-off',
};
