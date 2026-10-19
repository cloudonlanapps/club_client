import 'package:club_sdk_2/club_sdk_2.dart' show EventType;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_lib/ui_lib.dart'
    show Breakpoints, PageData, ResponsiveContainer;

import '../../../models/public/landing_events_section_fallback.dart';
import '../../../providers/public_events_by_type.dart';
import '../../../utils/landing_event_selection.dart';
import 'public_events_section.dart';
import 'public_events_section_error.dart';

/// A landing page's section for one event type: its copy from [pageData]
/// (the type's listing page), the few events `selectLandingEvents` picks,
/// and links to the full listing and each event's page.
///
/// Nothing shows while loading or when there is no live event of the type.
class LandingEventsSection extends ConsumerWidget {
  const LandingEventsSection({
    required this.type,
    required this.pageData,
    required this.onSeeAll,
    required this.onEventTap,
    this.visible = true,
    super.key,
  });

  /// The event type the section shows.
  final EventType type;

  /// The copy of the type's listing page: its landing section header, card
  /// labels and error title.
  final PageData pageData;

  /// Opens the type's full listing.
  final VoidCallback onSeeAll;

  /// Called with an event's public id when its card is tapped.
  final ValueChanged<String> onEventTap;

  /// Whether the section has scrolled into view.
  final bool visible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final split = ref.watch(publicEventsByTypeProvider(type));
    final isMobile =
        MediaQuery.sizeOf(context).width <
        Breakpoints.contentPageMobileMaxWidth;

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
            onSeeAll: onSeeAll,
            onEventTap: onEventTap,
          ),
        );
      },
    );
  }
}
