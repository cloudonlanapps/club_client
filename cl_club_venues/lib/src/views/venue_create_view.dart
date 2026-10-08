import 'dart:async';

import 'package:cl_club_forms/cl_club_forms.dart'
    show VenueCreateForm, VenueCreateFormState;
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show DiscardChangesPrompt, TitleRow;

import '../models/venue_form_helpers.dart';
import '../utils/venue_write_messages.dart';

/// Scaffold-free venue creation view.
///
/// Hosts [VenueCreateForm]: it owns the title and the actions, validates the
/// form from Create venue, runs the create, holds the in-flight flag, and
/// puts a server refusal of a field back on that field.
/// Navigation is delegated via [onCreated] and [onCancel] callbacks.
class VenueCreateView extends ConsumerStatefulWidget {
  const VenueCreateView({
    required this.onCreated,
    required this.onCancel,
    super.key,
  });

  final VoidCallback onCreated;
  final VoidCallback onCancel;

  @override
  ConsumerState<VenueCreateView> createState() => VenueCreateViewState();
}

class VenueCreateViewState extends ConsumerState<VenueCreateView> {
  final venueFormKey = GlobalKey<VenueCreateFormState>();
  bool isSubmitting = false;

  /// Validates the form and, when it is valid, creates the venue.
  Future<void> submit() async {
    final values = venueFormKey.currentState?.validate();
    if (values == null) return;
    await handleSubmit(values);
  }

  /// Creates the venue from the form's valid [values].
  Future<void> handleSubmit(Map<String, dynamic> values) async {
    setState(() => isSubmitting = true);
    try {
      final created = await VenueFormSubmit.create(
        values: values,
        notifier: ref.read(clVenuesMasterProvider.notifier),
      );
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast(description: Text('Venue "${created.name}" created.')),
      );
      widget.onCreated();
    } on Object catch (e) {
      if (!mounted) return;
      // A field the server refused shows the refusal on itself; anything
      // else is a failed create.
      final fieldErrors = VenueFormSubmit.createFieldErrors(e);
      if (fieldErrors.isNotEmpty) {
        venueFormKey.currentState?.showErrors(fieldErrors: fieldErrors);
        return;
      }
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(
            writeFailureMessage(e, fallback: venueCreateFailedMessage),
          ),
        ),
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
    final dirty = venueFormKey.currentState?.isDirty ?? false;
    if (dirty) {
      final discard = await DiscardChangesPrompt.show(context);
      if (!discard || !mounted) return;
    }
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
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
            title: 'New Venue',
            onBack: isSubmitting ? null : confirmCancel,
          ),
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: ShadCard(
                padding: EdgeInsets.zero,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      VenueCreateForm(
                        key: venueFormKey,
                        initialValues: buildVenueFormInitialValues(null),
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
                            onPressed: isSubmitting ? null : submit,
                            child: Text(
                              isSubmitting ? 'Creating…' : 'Create venue',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
