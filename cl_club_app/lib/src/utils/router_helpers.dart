import 'package:cl_remote_store/cl_remote_store.dart'
    show BroadcastScope, BroadcastScopeKind;
import 'package:club_sdk_2/club_sdk_2.dart' show EventType;
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_lib/ui_lib.dart' show ErrorTone, ErrorView;

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

/// The whole-number path parameter [name] of [state], or `null` when the
/// URL holds something else there (a typed or mangled link).
int? intPathParam(GoRouterState state, String name) =>
    int.tryParse(state.pathParameters[name] ?? '');

/// The page a route shows for a URL it cannot read, such as an id that is
/// not a number.
Page<void> notFoundPage(BuildContext context) => NoTransitionPage(
  child: ErrorView(
    title: 'Page not found',
    subtitle: 'This link does not lead to a page.',
    tone: ErrorTone.neutral,
    onHome: () => context.go('/'),
  ),
);

/// The Broadcast screen's route (club_client#252): one route, the audience
/// as its filter. No filter is all members.
const String broadcastRoute = '/memberzone/broadcast';

/// The Broadcast screen's URL for [scope]: [broadcastRoute] with `?group=`,
/// `?event=` or `?member=`.
String broadcastPath(BroadcastScope scope) {
  final query = switch (scope.kind) {
    BroadcastScopeKind.all => null,
    BroadcastScopeKind.group => 'group=${scope.id}',
    BroadcastScopeKind.event => 'event=${scope.id}',
    BroadcastScopeKind.member =>
      'member=${Uri.encodeQueryComponent(scope.username!)}',
  };
  return query == null ? broadcastRoute : '$broadcastRoute?$query';
}

/// The audience a Broadcast screen URL filters on ([broadcastPath]), or
/// `null` when the filter cannot be read: an id that is not a number, an
/// empty member, or more than one filter.
BroadcastScope? broadcastScopeFrom(Map<String, String> query) {
  final group = query['group'];
  final event = query['event'];
  final member = query['member'];
  final filters = [group, event, member].whereType<String>().length;
  if (filters == 0) return const BroadcastScope.all();
  if (filters > 1) return null;
  if (group != null) {
    final id = int.tryParse(group);
    return id == null ? null : BroadcastScope.group(id);
  }
  if (event != null) {
    final id = int.tryParse(event);
    return id == null ? null : BroadcastScope.event(id);
  }
  return member!.isEmpty ? null : BroadcastScope.member(member);
}

/// The admin's Applications page under Club Management (club_client#321,
/// #380): every template, to manage.
const String applicationsPath = '/memberzone/applications';

/// A member's Applications page under Main (club_client#380): the published
/// applications they are eligible for, to download.
const String myApplicationsPath = '$applicationsPath/mine';

/// The admin's editor of application template [id].
String applicationPath(int id) => '$applicationsPath/$id';
