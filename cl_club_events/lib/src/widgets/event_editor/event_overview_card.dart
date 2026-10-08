import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show EditableMarkdown;

import '../../models/camp_event_form_helpers.dart' show EventFormSubmit;
import '../../utils/event_save_error.dart';
import '../events_preview/cl_event_hero.dart';
import 'event_cover_upload_affordance.dart';

/// Hero card with the cover image and the event title, plus the description
/// edited inline via [EditableMarkdown].
class EventOverviewCard extends ConsumerWidget {
  const EventOverviewCard({required this.event, super.key});

  final Event event;

  Future<void> saveDescription(
    BuildContext context,
    WidgetRef ref,
    String updated,
  ) async {
    try {
      await EventFormSubmit.updateDescription(
        event: event,
        description: updated,
        notifier: ref.read(clEventsMasterProvider.notifier),
      );
    } on Object catch (e, st) {
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(
            eventSaveErrorMessage(
              e,
              stackTrace: st,
              fallback: 'Could not update description. Please try again.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClEventCover(event: event),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: EventCoverUploadAffordance(eventId: event.id),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(event.title, style: theme.textTheme.h4),
                const SizedBox(height: 12),
                EditableMarkdown(
                  data: event.description,
                  label: 'Description',
                  emptyText: 'No description provided.',
                  onSave: (updated) => saveDescription(context, ref, updated),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
