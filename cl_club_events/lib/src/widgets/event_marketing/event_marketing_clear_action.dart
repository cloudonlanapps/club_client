import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventMarketingMasterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ConfirmDialog;

import '../../utils/marketing_save_error.dart';

/// Removes an event's whole extended marketing block, after asking
/// (club_client#1). The basic block, on the event, stays.
class EventMarketingClearAction extends ConsumerStatefulWidget {
  const EventMarketingClearAction({required this.eventId, super.key});

  /// The event whose block is removed.
  final int eventId;

  @override
  ConsumerState<EventMarketingClearAction> createState() =>
      EventMarketingClearActionState();
}

/// State of [EventMarketingClearAction]: whether the removal is in flight.
class EventMarketingClearActionState
    extends ConsumerState<EventMarketingClearAction> {
  bool clearing = false;

  Future<void> clear() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Clear extended marketing?',
      message:
          'Details, fees, packages, offers, club membership and facilities '
          'are removed from this event. The basic marketing stays.',
      confirmLabel: 'Clear',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final toaster = ShadToaster.of(context);
    setState(() => clearing = true);
    try {
      await ref
          .read(clEventMarketingMasterProvider(widget.eventId).notifier)
          .clear();
      toaster.show(
        const ShadToast(description: Text('Extended marketing cleared.')),
      );
    } on Object catch (e, st) {
      toaster.show(
        ShadToast.destructive(
          description: Text(
            marketingSaveErrorMessage(
              e,
              stackTrace: st,
              fallback: 'Could not clear the marketing. Please try again.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => clearing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ShadButton.outline(
        enabled: !clearing,
        leading: const Icon(LucideIcons.eraser, size: 16),
        onPressed: clear,
        child: const Text('Clear extended marketing'),
      ),
    );
  }
}
