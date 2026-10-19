import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEventMarketingMasterNotifier, ClEventsMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart' show Event, EventMarketing;

import 'event_marketing_sections.dart';

/// Saves of the Marketing page's cards (club_client#1), through the masters.
abstract final class EventMarketingFormSubmit {
  /// The basic block: the four fields of the basic marketing form, on the
  /// event itself.
  static Future<Event> updateBasic({
    required Event event,
    required Map<String, dynamic> values,
    required ClEventsMasterNotifier notifier,
  }) {
    final next = EventMarketingSections.withBasic(event, values);
    return notifier.updateBasicMarketing(
      event,
      shortDescription: () => next.shortDescription,
      stamp: () => next.stamp,
      highlights: () => next.highlights,
      includes: () => next.includes,
    );
  }

  /// One section of the extended block: the [stored] block with [apply]
  /// giving the section the form's [values]. The whole block is written.
  static Future<EventMarketing> updateSection({
    required EventMarketing stored,
    required Map<String, dynamic> values,
    required EventMarketing Function(EventMarketing, Map<String, dynamic>)
    apply,
    required ClEventMarketingMasterNotifier notifier,
  }) => notifier.save(apply(stored, values));
}
