import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show Event;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show EditableSectionCard, EventEligibilityForm, EventEligibilityFormState;

import '../../models/camp_event_form_helpers.dart'
    show EventFormSubmit, buildEventFormInitialValues;
import '../../utils/event_save_error.dart';
import '../event_eligibility_read.dart';

/// Eligibility section — gender and the age band, edited in place.
///
/// While the editor holds a value (gender, an age or the Strict age check)
/// the card offers Reset beside Cancel and Save: it empties the form, and
/// Save then stores an event with no eligibility.
class EventEligibilityCard extends ConsumerStatefulWidget {
  const EventEligibilityCard({required this.event, super.key});

  final Event event;

  /// Widest the inline editor grows.
  static const double editMaxWidth = 420;

  @override
  ConsumerState<EventEligibilityCard> createState() =>
      EventEligibilityCardState();
}

class EventEligibilityCardState extends ConsumerState<EventEligibilityCard> {
  final formKey = GlobalKey<EventEligibilityFormState>();

  Future<bool> save(Map<String, dynamic> values) async {
    try {
      await EventFormSubmit.updateEligibility(
        event: widget.event,
        values: values,
        notifier: ref.read(clEventsMasterProvider.notifier),
      );
      if (!mounted) return true;
      ShadToaster.of(context).show(
        const ShadToast(description: Text('Eligibility updated.')),
      );
      return true;
    } on Object catch (e, st) {
      if (!mounted) return false;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(
            eventSaveErrorMessage(
              e,
              stackTrace: st,
              fallback: 'Could not update eligibility. Please try again.',
            ),
          ),
        ),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialValues = buildEventFormInitialValues(widget.event);
    return EditableSectionCard<Map<String, dynamic>>(
      title: 'Eligibility',
      leadingIcon: LucideIcons.userCheck,
      canEdit: true,
      editMaxWidth: EventEligibilityCard.editMaxWidth,
      read: EventEligibilityRead(event: widget.event),
      editBuilder: () => EventEligibilityForm(
        key: formKey,
        initialValues: initialValues,
        // The card's Reset shows only while the form holds a value.
        onChanged: () => setState(() {}),
      ),
      onValidate: () => formKey.currentState?.validate(),
      isDirty: () => formKey.currentState?.isDirty ?? false,
      onSave: save,
      onReset: () => formKey.currentState?.reset(),
      // Before the form is mounted (the frame the editor opens on), what it
      // is about to be seeded with answers.
      canReset: () =>
          formKey.currentState?.hasValue ??
          EventEligibilityForm.holdsValue(initialValues),
    );
  }
}
