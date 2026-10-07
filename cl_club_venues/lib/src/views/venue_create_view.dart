import 'package:cl_club_forms/cl_club_forms.dart'
    show VenueCreateForm, VenueCreateFormState;
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show TitleRow;

import '../models/venue_form_helpers.dart';
import '../utils/venue_write_messages.dart';

/// Scaffold-free venue creation view.
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

  Future<void> confirmCancel() async {
    final dirty = venueFormKey.currentState?.isDirty ?? false;
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
    final dirty = venueFormKey.currentState?.isDirty ?? false;
    return PopScope(
      canPop: !dirty && !isSubmitting,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await confirmCancel();
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
                                : () =>
                                      venueFormKey.currentState?.handleSubmit(),
                            child: Text(
                              isSubmitting ? 'Creating...' : 'Create venue',
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
