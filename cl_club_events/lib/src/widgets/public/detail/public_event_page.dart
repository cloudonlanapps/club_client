import 'package:club_sdk_2/club_sdk_2.dart' show EventType;
import 'package:flutter/material.dart';
import 'package:ui_lib/ui_lib.dart' show PageDataContent;

import '../../../models/public/event_detail_page_data.dart';
import '../../../models/public/public_event_view.dart';
import 'public_event_detail_content.dart';

/// An event's public page, as the website shows it: the event's banner
/// (stamp, title and short description), its detail sections and the CTA.
///
/// It reads nothing itself, so a host can draw an event that is not saved
/// yet: the member app's marketing preview does.
class PublicEventPage extends StatelessWidget {
  const PublicEventPage({
    required this.event,
    required this.copy,
    super.key,
    this.heroFallbackImageUri,
    this.onVenueTap,
    this.onNavigate,
  });

  /// The event.
  final PublicEventView event;

  /// The page's copy and the event's section labels.
  final EventDetailPageData copy;

  /// The banner's image, since an event has none of its own (a site's
  /// default page hero).
  final String? heroFallbackImageUri;

  /// Called with a venue's public id when its card is tapped.
  final ValueChanged<String>? onVenueTap;

  /// Called with the route of a CTA button.
  final ValueChanged<String>? onNavigate;

  @override
  Widget build(BuildContext context) {
    return PageDataContent(
      pageData: copy.pageData,
      heroFallbackImageUri: heroFallbackImageUri,
      heroLeftAlign: event.event.type == EventType.programme,
      heroUseStampBadge: true,
      useActiveSectionWrapper: false,
      onNavigate: onNavigate,
      activeContent: PublicEventDetailContent(
        event: event,
        labels: copy.labels,
        onVenueTap: onVenueTap,
      ),
    );
  }
}
