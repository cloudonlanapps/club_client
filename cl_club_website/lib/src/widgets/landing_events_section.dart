import 'package:cl_club_events/cl_club_events.dart'
    show
        PublicEventsSection,
        PublicEventsSectionError,
        publicEventsByTypeProvider,
        selectLandingEvents;
import 'package:club_sdk_2/club_sdk_2.dart' show EventType;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../page_content/landing_events_section_fallback.dart';
import '../page_content/page_type.dart';
import '../page_content/site_copy.dart';
import '../site/site_routes.dart';
import 'responsive_container.dart';

/// The landing page's section for one event type: its copy from the site's
/// strings, the few events `selectLandingEvents` picks, and links to the full
/// listing and each event's page.
///
/// Nothing shows while loading or when there is no live event of the type.
class LandingEventsSection extends ConsumerWidget {
  const LandingEventsSection({
    required this.type,
    this.visible = true,
    super.key,
  });

  /// Narrower than this is laid out for a phone.
  static const double mobileBreakpoint = 768;

  final EventType type;

  /// Whether the section has scrolled into view.
  final bool visible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final split = ref.watch(publicEventsByTypeProvider(type));
    final pageData = SiteCopy.of(context).pageData(switch (type) {
      EventType.camp => PageType.learningCamps,
      EventType.programme => PageType.trainingSessions,
      EventType.oneOff => PageType.clubEvents,
    });
    final isMobile = MediaQuery.sizeOf(context).width < mobileBreakpoint;

    return split.when(
      loading: () => const SizedBox.shrink(),
      error: (error, _) => PublicEventsSectionError(
        title: pageData.errorTitle ?? '',
        error: error.toString(),
      ),
      data: (split) {
        if (split.active.isEmpty) return const SizedBox.shrink();
        final header = pageData.landingSection;
        final fallback = LandingEventsSectionFallback.of(type);
        return ResponsiveContainer(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: isMobile ? 60 : 100,
          ),
          child: PublicEventsSection(
            type: type,
            events: selectLandingEvents(type, split.active),
            badge: header?.badge ?? fallback.badge,
            title: header?.title ?? fallback.title,
            description: header?.description ?? fallback.description,
            buttonText: header?.buttonText ?? fallback.buttonText,
            cardLabels: pageData.cardLabels,
            visible: visible,
            onSeeAll: () => context.go(SiteRoutes.listing(type)),
            onEventTap: (publicId) => context.go(SiteRoutes.event(publicId)),
          ),
        );
      },
    );
  }
}
