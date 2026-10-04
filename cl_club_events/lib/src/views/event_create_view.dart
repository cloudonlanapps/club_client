import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventsMasterProvider, clVenuesProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show Venue;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show
        EventCreateForm,
        EventCreateFormState,
        EventFormType,
        EventFormTypeLabel,
        EventVenueOption,
        TitleRow;

import '../models/event_create_form_helpers.dart';

/// Scaffold-free event creation view for a given [eventType].
///
/// Owns the chrome (title row, Create/Cancel buttons, discard prompt) and the
/// SDK call; the [EventCreateForm] it hosts stays pure-UI. Navigation is
/// delegated via [onCreated] and [onCancel] callbacks.
class EventCreateView extends ConsumerStatefulWidget {
  const EventCreateView({
    required this.eventType,
    required this.onCreated,
    required this.onCancel,
    super.key,
  });

  final EventFormType eventType;
  final VoidCallback onCreated;
  final VoidCallback onCancel;

  @override
  ConsumerState<EventCreateView> createState() => EventCreateViewState();
}

class EventCreateViewState extends ConsumerState<EventCreateView> {
  final eventFormKey = GlobalKey<EventCreateFormState>();
  bool isSubmitting = false;

  String get _label => widget.eventType.label;

  Future<void> handleSubmit(Map<String, dynamic> values) async {
    setState(() => isSubmitting = true);
    try {
      final created = await EventCreateFormSubmit.create(
        type: widget.eventType,
        values: values,
        notifier: ref.read(clEventsMasterProvider.notifier),
      );
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast(description: Text('$_label "${created.title}" created.')),
      );
      widget.onCreated();
    } on Object {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(
            'Could not create ${_label.toLowerCase()}. '
            'Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  Future<void> confirmCancel() async {
    final dirty = eventFormKey.currentState?.isDirty ?? false;
    if (!dirty) {
      widget.onCancel();
      return;
    }
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Discard changes?'),
        description: const Text('You have unsaved changes.'),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ShadButton.destructive(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      widget.onCancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dirty = eventFormKey.currentState?.isDirty ?? false;
    final venues =
        (ref
                    .watch(
                      clVenuesProvider(
                        (includeDeleted: false, searchTerm: null),
                      ),
                    )
                    .valueOrNull ??
                const <Venue>[])
            .map((v) => EventVenueOption(id: v.id, name: v.name))
            .toList();

    return PopScope(
      canPop: !dirty && !isSubmitting,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await confirmCancel();
      },
      child: Column(
        children: [
          TitleRow(
            title: 'New $_label',
            onBack: isSubmitting ? null : confirmCancel,
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                children: [
                  EventCreateForm(
                    key: eventFormKey,
                    eventType: widget.eventType,
                    venues: venues,
                    initialValues: buildEventCreateFormInitialValues(
                      widget.eventType,
                    ),
                    isSubmitting: isSubmitting,
                    onSubmit: handleSubmit,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ShadButton.outline(
                        onPressed: isSubmitting ? null : confirmCancel,
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ShadButton.outline(
                        onPressed: isSubmitting
                            ? null
                            : () => eventFormKey.currentState?.handleSubmit(),
                        child: Text(
                          isSubmitting
                              ? 'Creating...'
                              : 'Create ${_label.toLowerCase()}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
