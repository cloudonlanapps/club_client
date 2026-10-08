import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/camp_event_form_helpers.dart' show EventFormSubmit;
import '../../utils/event_save_error.dart';

/// Boolean flags — toggling a checkbox immediately persists the change
/// (disabled while a save is in flight). Mirrors `VenueFlagsCard`.
class EventFlagsCard extends ConsumerStatefulWidget {
  const EventFlagsCard({required this.event, super.key});

  final Event event;

  @override
  ConsumerState<EventFlagsCard> createState() => EventFlagsCardState();
}

class EventFlagsCardState extends ConsumerState<EventFlagsCard> {
  bool isSaving = false;

  Future<void> handleToggle({Visibility? visibility, bool? isFeatured}) async {
    setState(() => isSaving = true);
    try {
      await EventFormSubmit.updateFlags(
        event: widget.event,
        notifier: ref.read(clEventsMasterProvider.notifier),
        visibility: visibility,
        isFeatured: isFeatured,
      );
    } on Object catch (e, st) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(
            eventSaveErrorMessage(
              e,
              stackTrace: st,
              fallback: 'Could not update event. Please try again.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final isPrivate = event.visibility == Visibility.private;
    return ShadCard(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShadCheckbox(
            value: isPrivate,
            enabled: !isSaving,
            onChanged: (v) => handleToggle(
              visibility: v ? Visibility.private : Visibility.public,
            ),
            label: const Text('This is a private event'),
          ),
          const SizedBox(height: 12),
          ShadCheckbox(
            value: event.isFeatured,
            enabled: !isSaving,
            onChanged: (v) => handleToggle(isFeatured: v),
            label: const Text('This event is featured'),
          ),
        ],
      ),
    );
  }
}
