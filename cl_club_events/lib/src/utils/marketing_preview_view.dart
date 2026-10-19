import 'package:cl_remote_store/cl_remote_store.dart' show MediaUrlBuilder;
import 'package:club_sdk_2/club_sdk_2.dart'
    show
        Event,
        EventMarketing,
        EventMarketingBasic,
        EventType,
        PublicEvent,
        PublicVenue,
        Venue;

import '../models/public/public_event_view.dart';

/// The public id a previewed event goes by: it is not published under it.
const String marketingPreviewPublicId = 'preview';

/// [event] as its public page would show it, for the marketing preview
/// (club_client#1): the staff event's own fields, [venue], and the
/// extended block [marketing] when the module is on.
///
/// The staff event has no public id, and its media go through signed-in
/// links the public page cannot use, so the preview carries no cover or
/// gallery. Whether it is past is worked out here: a programme with no end
/// never is; anything else is once its last occurrence has ended.
PublicEventView marketingPreviewView({
  required Event event,
  required MediaUrlBuilder media,
  required DateTime now,
  Venue? venue,
  EventMarketing? marketing,
}) {
  final until = event.untilTimeUtc;
  final endless = event.type == EventType.programme && until == null;
  final isPast = !endless && (until ?? event.endTimeUtc).isBefore(now);
  final hasBasic =
      event.shortDescription != null ||
      event.stamp != null ||
      (event.highlights?.isNotEmpty ?? false) ||
      (event.includes?.isNotEmpty ?? false);
  return PublicEventView(
    media: media,
    marketing: marketing,
    event: PublicEvent(
      publicId: marketingPreviewPublicId,
      title: event.title,
      description: event.description,
      type: event.type,
      venueId: marketingPreviewPublicId,
      startTimeUtc: event.startTimeUtc,
      endTimeUtc: event.endTimeUtc,
      venue: PublicVenue(
        publicId: marketingPreviewPublicId,
        name: venue?.name ?? '',
        address: venue?.address,
        description: venue?.description,
        mapUri: venue?.mapUri,
      ),
      createdAtUtc: event.createdAtUtc,
      updatedAtUtc: event.updatedAtUtc,
      rrule: event.rrule,
      untilTimeUtc: until,
      sessions: event.sessions,
      genders: event.genders,
      minAge: event.minAge,
      maxAge: event.maxAge,
      strictAge: event.strictAge,
      dobOnOrAfterUtc: event.dobOnOrAfterUtc,
      dobOnOrBeforeUtc: event.dobOnOrBeforeUtc,
      eligibilityReferenceDayUtc: event.eligibilityReferenceDayUtc,
      isFeatured: event.isFeatured,
      isPast: isPast,
      coaches: event.coaches ?? const [],
      marketing: hasBasic
          ? EventMarketingBasic(
              shortDescription: event.shortDescription,
              stamp: event.stamp,
              highlights: event.highlights,
              includes: event.includes,
            )
          : null,
    ),
  );
}
