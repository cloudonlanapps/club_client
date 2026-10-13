import 'package:cl_remote_store/cl_remote_store.dart'
    show
        eventCoverImageProvider,
        eventMediaMutationProvider,
        imagePickerProvider;
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ImageUploadAffordance;

import '../../utils/event_save_error.dart';
import 'event_image_pick.dart';

/// Circular pencil affordance overlaid on the cover image — lets an admin
/// replace (and, when one exists, remove) the event cover. Uploads go through
/// the v2 media-link flow (`eventMediaMutationProvider`), like the user avatar.
class EventCoverUploadAffordance extends ConsumerStatefulWidget {
  const EventCoverUploadAffordance({required this.eventId, super.key});

  final int eventId;

  @override
  ConsumerState<EventCoverUploadAffordance> createState() =>
      EventCoverUploadAffordanceState();
}

class EventCoverUploadAffordanceState
    extends ConsumerState<EventCoverUploadAffordance> {
  /// Picks + confirms an image, then uploads it as the event cover. The
  /// re-entrancy guard lives in [ImageUploadAffordance]; this only owns the
  /// SDK call and its error toast.
  Future<void> replace() async {
    final picked = await pickAndConfirmEventImage(
      context,
      picker: ref.read(imagePickerProvider),
    );
    if (picked == null || !mounted) return;
    try {
      await ref
          .read(eventMediaMutationProvider(widget.eventId).notifier)
          .uploadCover(
            bytes: picked.bytes,
            filename: picked.filename,
            contentType: picked.mimeType,
          );
    } on Object catch (e, st) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(
            eventSaveErrorMessage(
              e,
              stackTrace: st,
              fallback: 'Could not update cover. Please try again.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> remove() async {
    try {
      await ref
          .read(eventMediaMutationProvider(widget.eventId).notifier)
          .clearCover();
    } on Object catch (e, st) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(
            eventSaveErrorMessage(
              e,
              stackTrace: st,
              fallback: 'Could not remove cover. Please try again.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uploading = ref
        .watch(eventMediaMutationProvider(widget.eventId))
        .isLoading;
    final hasCover =
        ref.watch(eventCoverImageProvider(widget.eventId)).valueOrNull != null;
    return ImageUploadAffordance(
      uploading: uploading,
      onReplace: replace,
      onRemove: hasCover ? remove : null,
    );
  }
}
