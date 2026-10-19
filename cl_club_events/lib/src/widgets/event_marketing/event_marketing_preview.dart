import 'package:cl_remote_store/cl_remote_store.dart'
    show SiteMediaSlot, clPublicMediaUrlProvider, clPublicSiteMediaProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show Event, EventMarketing, Venue;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../utils/default_event_detail_copy.dart';
import '../../utils/marketing_preview_view.dart';
import '../public/detail/public_event_page.dart';
import '../public/public_event_card.dart';

/// The live preview of an event's Marketing page (club_client#1): the
/// event's card as the website lists it, then its page as the website
/// shows it, drawn from [event] and [marketing] as they are being edited.
///
/// It is laid out for the width it is given, not the window's, so a half
/// of a wide screen previews the page as a narrow browser would. Its
/// buttons go nowhere.
class EventMarketingPreview extends ConsumerWidget {
  const EventMarketingPreview({
    required this.event,
    this.venue,
    this.marketing,
    super.key,
  });

  /// Widest the event's card is drawn.
  static const double cardMaxWidth = 420;

  /// Gap around the card.
  static const double cardPadding = 16;

  /// The event, with any unsaved basic marketing.
  final Event event;

  /// The event's venue, once loaded.
  final Venue? venue;

  /// The extended block with any unsaved section, or null when the module
  /// is off.
  final EventMarketing? marketing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final view = marketingPreviewView(
      event: event,
      venue: venue,
      marketing: marketing,
      media: ref.watch(clPublicMediaUrlProvider),
      now: DateTime.now(),
    );
    final hero = ref
        .watch(clPublicSiteMediaProvider(SiteMediaSlot.pageHeroDefault))
        ?.uri;
    return LayoutBuilder(
      builder: (context, constraints) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            size: Size(constraints.maxWidth, media.size.height),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: cardPadding,
                    children: [
                      Text('On the listing', style: theme.textTheme.small),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: cardMaxWidth,
                        ),
                        child: PublicEventCard(event: view),
                      ),
                      Text('Its page', style: theme.textTheme.small),
                    ],
                  ),
                ),
                PublicEventPage(
                  event: view,
                  copy: defaultEventDetailCopy(view),
                  heroFallbackImageUri: hero,
                  onNavigate: (_) {},
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
