import 'dart:async';

import 'package:cl_club_forms/cl_club_forms.dart'
    show
        EventCreateForm,
        EventCreateFormState,
        EventFormType,
        EventFormTypeLabel,
        EventVenueOption;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventsMasterProvider, clVenuesProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show Venue;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show DiscardChangesPrompt, TitleRow;

import '../models/event_create_form_helpers.dart';
import '../utils/event_create_error.dart';

/// Scaffold-free event creation view for a given [eventType].
///
/// Owns the chrome (title row, Create/Cancel buttons, discard prompt), the
/// in-flight state and the SDK call; the [EventCreateForm] it hosts stays
/// pure-UI. Create validates the form and runs the create; a refusal the
/// server makes about a field goes back on that field, any other failure is
/// a toast. Navigation is delegated via [onCreated] and [onCancel]
/// callbacks.
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

  /// What the event type is called in the title, the button and the toasts.
  String get label => widget.eventType.label;

  /// Shown when the create fails with nothing more specific to say.
  String get failedMessage =>
      'Could not create ${label.toLowerCase()}. Please try again.';

  /// Validates the form and creates the event; a refusal about a field
  /// shows on that field.
  Future<void> create() async {
    final form = eventFormKey.currentState;
    if (form == null || isSubmitting) return;
    final values = form.validate();
    if (values == null) return;
    setState(() => isSubmitting = true);
    try {
      final created = await EventCreateFormSubmit.create(
        type: widget.eventType,
        values: values,
        notifier: ref.read(clEventsMasterProvider.notifier),
      );
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast(description: Text('$label "${created.title}" created.')),
      );
      widget.onCreated();
    } on Object catch (e) {
      if (!mounted) return;
      final refusal = eventCreateRefusal(e, fallback: failedMessage);
      if (refusal != null) {
        eventFormKey.currentState?.showErrors(
          fieldErrors: refusal.fieldErrors,
          formError: refusal.formError,
        );
        return;
      }
      ShadToaster.of(context).show(
        ShadToast.destructive(description: Text(failedMessage)),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  /// Leaves the view by Cancel, the back arrow or a system back. Asks first
  /// when the form holds changes, read at that moment; does nothing while
  /// the create is in flight.
  Future<void> confirmCancel() async {
    if (isSubmitting) return;
    final dirty = eventFormKey.currentState?.isDirty ?? false;
    if (dirty) {
      final discard = await DiscardChangesPrompt.show(context);
      if (!discard || !mounted) return;
    }
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
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
      // A system back never pops by itself: whether the form holds changes
      // is only known when back is pressed, so the handler decides.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(confirmCancel());
      },
      child: Column(
        children: [
          TitleRow(
            title: 'New $label',
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
                    enabled: !isSubmitting,
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
                        onPressed: isSubmitting ? null : create,
                        child: Text(
                          isSubmitting
                              ? 'Creating…'
                              : 'Create ${label.toLowerCase()}',
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
