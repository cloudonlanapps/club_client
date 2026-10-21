import 'package:cl_member_auth/cl_member_auth.dart' show canManageEvent;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        clEventDetailProvider,
        clEventMarketingMasterProvider,
        clVenueDetailProvider,
        eventMarketingProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;
import 'package:ui_lib/ui_lib.dart'
    show EditorPreviewLayout, ErrorTone, ErrorView, LoadingView, TitleRow;

import '../models/event_marketing_sections.dart';
import '../models/marketing_section.dart';
import '../widgets/event_marketing/event_marketing_editor_column.dart';
import '../widgets/event_marketing/event_marketing_preview.dart';

/// An event's Marketing page (club_client#1): what the website shows about
/// the event, edited section by section, beside a live preview of the
/// event's card and page.
///
/// For an admin or the event's organizer ([canManageEvent]); anyone else
/// is told so. The Basic card is always there; the extended block's cards
/// only where the deployment runs the Event Marketing module. What is
/// typed shows in the preview before it is saved: each open editor's
/// values are held here as a draft, and dropped when the editor closes.
class EventMarketingView extends ConsumerStatefulWidget {
  const EventMarketingView({
    required this.currentUser,
    required this.eventId,
    required this.onHome,
    this.onBack,
    super.key,
  });

  /// The viewer, a coach or an admin (the screen's gate).
  final UserPrivate currentUser;

  /// The event.
  final int eventId;

  /// Leaves the page.
  final VoidCallback? onBack;

  /// Goes home from the not-allowed message.
  final VoidCallback onHome;

  @override
  ConsumerState<EventMarketingView> createState() => EventMarketingViewState();
}

/// State of [EventMarketingView]: the drafts of the open editors.
class EventMarketingViewState extends ConsumerState<EventMarketingView> {
  /// What is being typed in each open editor, by section.
  final Map<MarketingSection, Map<String, dynamic>> drafts = {};

  /// Holds [values] as the draft of [section], or drops it when null.
  void setDraft(MarketingSection section, Map<String, dynamic>? values) {
    setState(() {
      if (values == null) {
        drafts.remove(section);
      } else {
        drafts[section] = values;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.currentUser;
    assert(
      user.isCoachOrAdmin,
      'EventMarketingView called for ${user.username}, who is neither a '
      'coach nor an admin. Screen gate failed.',
    );
    final eventAsync = ref.watch(clEventDetailProvider(widget.eventId));
    final module = ref.watch(eventMarketingProvider) ?? false;
    final extended = module
        ? ref.watch(clEventMarketingMasterProvider(widget.eventId))
        : null;
    return eventAsync.when(
      skipLoadingOnReload: true,
      loading: () => const LoadingView(),
      error: (_, _) => const Center(child: Text('Could not load the event.')),
      data: (event) {
        if (!canManageEvent(event, user)) {
          return ErrorView(
            tone: ErrorTone.neutral,
            icon: LucideIcons.shieldAlert,
            title: 'Access Denied',
            subtitle:
                "Only an admin or the event's organizer edits its marketing.",
            onHome: widget.onHome,
          );
        }
        final basic = drafts[MarketingSection.basic];
        var marketing = extended?.valueOrNull;
        for (final entry in drafts.entries) {
          if (marketing == null) break;
          marketing = EventMarketingSections.withSection(
            marketing,
            entry.key,
            entry.value,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitleRow(
              title: 'Marketing',
              subtitle: event.title,
              onBack: widget.onBack,
            ),
            const Divider(height: 1),
            Expanded(
              child: EditorPreviewLayout(
                editor: EventMarketingEditorColumn(
                  event: event,
                  extended: extended,
                  onDraft: setDraft,
                ),
                preview: EventMarketingPreview(
                  event: basic == null
                      ? event
                      : EventMarketingSections.withBasic(event, basic),
                  venue: ref
                      .watch(clVenueDetailProvider(event.venueId))
                      .valueOrNull,
                  marketing: marketing,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
