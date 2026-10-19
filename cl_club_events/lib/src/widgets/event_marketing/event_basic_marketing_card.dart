import 'package:cl_club_forms/cl_club_forms.dart' show EventBasicMarketingForm;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show Event;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import '../../models/event_marketing_form_helpers.dart';
import '../../models/event_marketing_form_submit.dart';
import '../../models/marketing_read_entries.dart';
import 'event_marketing_section_card.dart';

/// The Basic card of an event's Marketing page (club_client#1): its short
/// description, stamp, highlights and includes, stored on the event.
class EventBasicMarketingCard extends ConsumerWidget {
  const EventBasicMarketingCard({
    required this.event,
    required this.onDraft,
    super.key,
  });

  /// The event, as stored.
  final Event event;

  /// Given what is being typed, or null when the editor closes.
  final ValueChanged<Map<String, dynamic>?> onDraft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EventMarketingSectionCard(
      title: 'Basic',
      icon: LucideIcons.stamp,
      savedMessage: 'Basic marketing updated.',
      entries: MarketingReadEntries.basic(event),
      onDraft: onDraft,
      formBuilder: ({required key, required enabled, required onChanged}) =>
          EventBasicMarketingForm(
            key: key,
            initialValues: buildEventBasicMarketingFormInitialValues(event),
            enabled: enabled,
            onChanged: onChanged,
          ),
      onSave: (values) => EventMarketingFormSubmit.updateBasic(
        event: event,
        values: values,
        notifier: ref.read(clEventsMasterProvider.notifier),
      ),
    );
  }
}
