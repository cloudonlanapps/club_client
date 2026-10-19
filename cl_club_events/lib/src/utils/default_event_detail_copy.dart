import 'package:ui_lib/ui_lib.dart'
    show PageCtaData, PageData, PageEmptyStateData, PageHeroData;

import '../extensions/public_event_view_dates.dart';
import '../models/public/default_event_detail_labels.dart';
import '../models/public/event_detail_page_data.dart';
import '../models/public/public_event_view.dart';

/// A CTA button's route where the page leads nowhere (a preview).
const String defaultEventPageRoute = '';

/// The copy of [event]'s page for a host with no site copy of its own (the
/// member app's marketing preview), in plain English: the hero is the
/// event's stamp, title and short description, and the CTA follows the
/// event's registration state as the website's does.
EventDetailPageData defaultEventDetailCopy(PublicEventView event) {
  return EventDetailPageData(
    pageData: PageData(
      hero: PageHeroData(
        title: event.title,
        badge: event.stamp,
        description: event.tagline,
      ),
      emptyState: const PageEmptyStateData(
        iconName: 'calendar',
        title: 'No Content',
        description: 'Event details unavailable.',
        buttonText: 'Contact Us',
      ),
      cta: switch (event.ctaState) {
        PublicEventCtaState.closed => const PageCtaData(
          title: 'Registration Closed',
          description:
              'The registration deadline has passed. Contact us for '
              'inquiries.',
          primaryButtonText: 'Contact Us',
          primaryRoute: defaultEventPageRoute,
        ),
        PublicEventCtaState.completed => const PageCtaData(
          title: 'This Event Has Ended',
          description: 'Thank you to all participants!',
          primaryButtonText: 'View Upcoming Events',
          primaryRoute: defaultEventPageRoute,
        ),
        _ => PageCtaData(
          title: 'Ready to Join?',
          description: event.formattedDeadline.isEmpty
              ? 'Register to confirm your spot'
              : 'Register before ${event.formattedDeadline} to confirm your '
                    'spot',
          primaryButtonText: 'Register Now',
          primaryRoute: defaultEventPageRoute,
        ),
      },
    ),
    labels: defaultEventDetailLabels,
  );
}
