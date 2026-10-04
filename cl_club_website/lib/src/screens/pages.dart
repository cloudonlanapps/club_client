import 'package:cl_club_events/cl_club_events.dart'
    show
        PublicEventCardGrid,
        PublicEventCardList,
        PublicEventDetailContent,
        PublicEventViewDates,
        publicEventByIdProvider,
        publicEventsByTypeProvider;
import 'package:cl_club_members/cl_club_members.dart' show CoachesCardList;
import 'package:cl_club_venues/cl_club_venues.dart'
    show PublicVenueList, VenueContent;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        clPublicClubContentProvider,
        clPublicMediaUrlProvider,
        clPublicStaffProvider,
        clPublicVenueProvider,
        clPublicVenuesProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/site_config.dart';
import '../page_content/page_common.dart';
import '../page_content/page_data.dart';
import '../page_content/page_type.dart';
import '../page_content/site_copy.dart';
import '../site/site_routes.dart';
import '../widgets/club_content_section.dart';
import '../widgets/contact_content_section.dart';
import '../widgets/not_found_page.dart';
import '../widgets/page_data_scaffold.dart';
import '../widgets/public_page_shell.dart';

/// Learning Camps page - displays the club's camps.
/// Shows active camps at the top and past camps below.
class LearningCampsPage extends ConsumerWidget {
  const LearningCampsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campsDataAsync = ref.watch(
      publicEventsByTypeProvider(EventType.camp),
    );
    final cardLabels = SiteCopy.of(
      context,
    ).pageData(PageType.learningCamps).cardLabels;

    return PublicPageShell(
      pageTitle: 'Learn to Play',
      child: PageDataScaffold(
        pageType: PageType.learningCamps,
        activeContent: campsDataAsync.when(
          data: (data) => data.active.isEmpty
              ? null
              : PublicEventCardList(
                  events: data.active,
                  cardLabels: cardLabels,
                  onEventTap: (publicId) =>
                      context.go(SiteRoutes.event(publicId)),
                ),
          loading: () => const LoadingContent(),
          error: (e, _) =>
              ErrorContent(error: e.toString(), title: 'Failed to load camps'),
        ),
        pastContent: campsDataAsync.whenOrNull(
          data: (data) => data.past.isEmpty
              ? null
              : PublicEventCardGrid(
                  events: data.past,
                  cardLabels: cardLabels,
                  onEventTap: (publicId) =>
                      context.go(SiteRoutes.event(publicId)),
                ),
        ),
      ),
    );
  }
}

/// Training Sessions page - displays ongoing programs.
class TrainingSessionsPage extends ConsumerWidget {
  const TrainingSessionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programsAsync = ref.watch(
      publicEventsByTypeProvider(EventType.programme),
    );
    final cardLabels = SiteCopy.of(
      context,
    ).pageData(PageType.trainingSessions).cardLabels;

    return PublicPageShell(
      pageTitle: 'Training Sessions',
      child: PageDataScaffold(
        pageType: PageType.trainingSessions,
        activeContent: programsAsync.when(
          // Programmes are ongoing: the page shows the live ones and has no
          // past section, so the split's `past` half goes unread here.
          data: (split) => split.active.isEmpty
              ? null
              : PublicEventCardList(
                  events: split.active,
                  cardLabels: cardLabels,
                  onEventTap: (publicId) =>
                      context.go(SiteRoutes.event(publicId)),
                ),
          loading: () => const LoadingContent(),
          error: (e, _) => ErrorContent(
            error: e.toString(),
            title: 'Failed to load programs',
          ),
        ),
      ),
    );
  }
}

/// Club Events page - displays one-off events.
/// Shows active events at the top and past events below.
class ClubEventsPage extends ConsumerWidget {
  const ClubEventsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsDataAsync = ref.watch(
      publicEventsByTypeProvider(EventType.oneOff),
    );
    final cardLabels = SiteCopy.of(
      context,
    ).pageData(PageType.clubEvents).cardLabels;

    return PublicPageShell(
      pageTitle: 'Club Events',
      child: PageDataScaffold(
        pageType: PageType.clubEvents,
        activeContent: eventsDataAsync.when(
          data: (data) => data.active.isEmpty
              ? null
              : PublicEventCardList(
                  events: data.active,
                  cardLabels: cardLabels,
                  onEventTap: (publicId) =>
                      context.go(SiteRoutes.event(publicId)),
                ),
          loading: () => const LoadingContent(),
          error: (e, _) =>
              ErrorContent(error: e.toString(), title: 'Failed to load events'),
        ),
        pastContent: eventsDataAsync.whenOrNull(
          data: (data) => data.past.isEmpty
              ? null
              : PublicEventCardGrid(
                  events: data.past,
                  cardLabels: cardLabels,
                  onEventTap: (publicId) =>
                      context.go(SiteRoutes.event(publicId)),
                ),
        ),
      ),
    );
  }
}

/// Ice Masters page - displays coaching staff.
class IceMastersPage extends ConsumerWidget {
  const IceMastersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coachesAsync = ref.watch(clPublicStaffProvider);

    return PublicPageShell(
      pageTitle: 'Ice Masters',
      child: PageDataScaffold(
        pageType: PageType.iceMasters,
        activeContent: coachesAsync.when(
          data: (coaches) =>
              coaches.isEmpty ? null : CoachesCardList(coaches: coaches),
          loading: () => const LoadingContent(),
          error: (e, _) => ErrorContent(
            error: e.toString(),
            title: 'Failed to load coaches',
          ),
        ),
      ),
    );
  }
}

/// The Rinks page - displays venue/locations.
class TheRinksPage extends ConsumerWidget {
  const TheRinksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venuesAsync = ref.watch(clPublicVenuesProvider);

    return PublicPageShell(
      pageTitle: 'The Rinks',
      child: PageDataScaffold(
        pageType: PageType.theRinks,
        activeContent: venuesAsync.when(
          data: (venues) => venues.isEmpty
              ? null
              : PublicVenueList(
                  venues: venues,
                  onVenueTap: (publicId) =>
                      context.go(SiteRoutes.venue(publicId)),
                ),
          loading: () => const LoadingContent(),
          error: (e, _) =>
              ErrorContent(error: e.toString(), title: 'Failed to load venues'),
        ),
      ),
    );
  }
}

/// The Club page - displays club history, mission, vision, and values.
class TheClubPage extends ConsumerWidget {
  const TheClubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The bundled copy is passed in rather than looked up inside the provider:
    // only a widget can reach the localisations.
    final clubInfo = ref.watch(
      clPublicClubContentProvider(SiteCopy.of(context).clubInfo),
    );
    return PublicPageShell(
      pageTitle: 'About Us',
      child: PageDataScaffold(
        pageType: PageType.theClub,
        activeContent: ClubContentSection(clubInfo: clubInfo),
      ),
    );
  }
}

/// Contact Us page - displays contact info card and map.
///
/// Fully offline, and deliberately not gated by the network status check: the
/// page a visitor reaches when something is wrong should not itself depend on
/// the server being up.
class ContactUsPage extends ConsumerWidget {
  const ContactUsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = SiteCopy.of(context);

    return PublicPageShell(
      pageTitle: 'Contact Us',
      child: PageDataContent(
        pageData: copy.pageData(PageType.contactUs),
        activeContent: ContactContentSection(
          contactPageLabels: copy.contactLabels,
          mapConfig: ref.watch(siteConfigProvider).map,
          whatsappLabel: copy.strings.contactInfoWhatsappLabel,
        ),
      ),
    );
  }
}

/// Unified event detail page - handles camps, programs, and one-off events.
/// Route: /public/events/:publicId
class EventDetailPage extends ConsumerWidget {
  const EventDetailPage({
    required this.publicId,
    required this.notFoundKey,
    super.key,
  });

  /// The event's opaque public id, straight from the URL.
  final String publicId;

  /// Key for NotFoundPage labels when event not found.
  final String notFoundKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(publicEventByIdProvider(publicId));

    return eventAsync.when(
      data: (event) {
        if (event == null) {
          return NotFoundPage(notFoundKey: notFoundKey);
        }
        final isProgram = event.event.type == EventType.programme;
        final detailData = SiteCopy.of(context).eventDetail(
          event.type,
          badge: event.stamp,
          title: event.title,
          description: event.tagline,
          ctaState: event.ctaState,
          deadline: event.formattedDeadline,
        );

        return PublicPageShell(
          pageTitle: event.title,
          child: PageDataContent(
            pageData: detailData.pageData,
            heroLeftAlign: isProgram,
            heroUseStampBadge: true,
            useActiveSectionWrapper: false,
            activeContent: PublicEventDetailContent(
              event: event,
              labels: detailData.labels,
              onVenueTap: (publicId) => context.go(SiteRoutes.venue(publicId)),
            ),
          ),
        );
      },
      loading: () => const PublicPageShell(
        pageTitle: 'Loading...',
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => NotFoundPage(notFoundKey: notFoundKey),
    );
  }
}

/// Venue detail page - displays venue information from the database.
class VenuePage extends ConsumerWidget {
  const VenuePage({required this.publicId, super.key});

  /// The venue's opaque public id, straight from the URL.
  final String publicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venueAsync = ref.watch(clPublicVenueProvider(publicId));

    return venueAsync.when(
      loading: () => const PublicPageShell(
        pageTitle: 'Loading...',
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const NotFoundPage(notFoundKey: 'venue'),
      data: (venue) {
        // Create PageData from venue
        final pageData = PageData(
          hero: PageHeroData(
            title: venue.name,
            description: venue.address,
            // Server media, as a descriptor. Null falls through to the
            // site's default hero slot rather than collapsing the hero.
            imageUri: ref.watch(clPublicMediaUrlProvider)(venue.image),
          ),
          emptyState: const PageEmptyStateData(
            iconName: 'mapPin',
            title: 'No Information',
            description: 'Venue information unavailable.',
            buttonText: 'Contact Us',
          ),
        );

        return PublicPageShell(
          pageTitle: venue.name,
          child: PageDataContent(
            pageData: pageData,
            heroIcon: LucideIcons.mapPin,
            useActiveSectionWrapper: false,
            activeContent: VenueContent(
              description: venue.description,
              mapUri: venue.mapUri,
              selectable: false,
            ),
          ),
        );
      },
    );
  }
}
