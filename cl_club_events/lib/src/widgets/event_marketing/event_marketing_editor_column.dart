import 'package:club_sdk_2/club_sdk_2.dart' show Event, EventMarketing;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/marketing_section.dart';
import 'event_basic_marketing_card.dart';
import 'event_marketing_clear_action.dart';
import 'event_marketing_extended_cards.dart';

/// The editor side of an event's Marketing page (club_client#1): the Basic
/// card, then, where the module runs, the extended block's cards and its
/// Clear action.
class EventMarketingEditorColumn extends StatelessWidget {
  const EventMarketingEditorColumn({
    required this.event,
    required this.extended,
    required this.onDraft,
    super.key,
  });

  /// Padding around the cards.
  static const double padding = 16;

  /// The event, as stored.
  final Event event;

  /// The extended block as stored, while it loads or when it failed;
  /// null when the module is off.
  final AsyncValue<EventMarketing>? extended;

  /// Given a section and what is being typed in it, or null when its
  /// editor closes.
  final void Function(MarketingSection section, Map<String, dynamic>? values)
  onDraft;

  @override
  Widget build(BuildContext context) {
    final block = extended;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: EventMarketingExtendedCards.cardGap,
        children: [
          EventBasicMarketingCard(
            event: event,
            onDraft: (values) => onDraft(MarketingSection.basic, values),
          ),
          if (block != null)
            block.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) =>
                  const Text('Could not load the extended marketing.'),
              data: (marketing) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: EventMarketingExtendedCards.cardGap,
                children: [
                  EventMarketingExtendedCards(
                    eventId: event.id,
                    marketing: marketing,
                    onDraft: onDraft,
                  ),
                  EventMarketingClearAction(eventId: event.id),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
