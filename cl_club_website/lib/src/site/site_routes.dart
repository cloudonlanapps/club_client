import 'package:cl_club_events/cl_club_events.dart'
    show EventHighlight, Highlight;
import 'package:club_sdk_2/club_sdk_2.dart' show EventType;

import '../page_content/site_copy.dart';

/// The site's routes, for the callbacks it hands to the feature packages'
/// public widgets.
///
/// The feature packages navigate by callback and never name a route; the
/// site, which owns the router, builds the path here.
abstract final class SiteRoutes {
  /// Prefix of an event's page.
  static const String eventPrefix = '/public/events';

  /// Prefix of a venue's page.
  static const String venuePrefix = '/public/rink';

  /// The page of the event with [publicId].
  static String event(String publicId) => '$eventPrefix/$publicId';

  /// The page of the venue with [publicId].
  static String venue(String publicId) => '$venuePrefix/$publicId';

  /// The listing of every event of [type].
  static String listing(EventType type) => switch (type) {
    EventType.camp => SiteCopy.routeCamps,
    EventType.programme => SiteCopy.routePrograms,
    EventType.oneOff => SiteCopy.routeOneOff,
  };

  /// Where a landing highlight leads, or null when it has no page.
  static String? highlight(Highlight highlight) => switch (highlight) {
    EventHighlight(:final view) => event(view.publicId),
    _ => null,
  };
}
