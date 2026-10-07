import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/event_staff_member.dart';
import '../../models/event_staff_pickers.dart';
import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../form/labeled_form_row.dart';
import 'event_form_fields.dart';
import 'event_staff_coaches_field.dart';
import 'event_staff_form_strings.dart';
import 'event_staff_form_validators.dart';
import 'event_staff_form_values.dart';
import 'event_staff_organizer_field.dart';

/// Pure-UI form for an event's organizer and coaches (no SDK / no Riverpod),
/// driven entirely by pickers (no free-text entry).
///
/// * The organizer is required and changed via a **Transfer** action; an
///   event without one shows *Unassigned* and cannot be saved until one is
///   picked.
/// * Coaches are a list with per-row removal shown as a strikethrough + Undo
///   (so a removal can be reverted before saving), plus an **Add coaches**
///   action.
///
/// The host supplies the candidate pickers ([onPickOrganizer] /
/// [onPickCoaches]) and drives the form through a
/// `GlobalKey<EventStaffFormState>` ([FormContract]).
class EventStaffForm extends StatefulWidget {
  const EventStaffForm({
    required this.initialCoaches,
    required this.onPickOrganizer,
    required this.onPickCoaches,
    this.initialOrganizer,
    this.enabled = true,
    super.key,
  });

  /// The event's organizer; null when it has none.
  final EventStaffMember? initialOrganizer;

  /// The event's coaches.
  final List<EventStaffMember> initialCoaches;

  /// Picks the organizer to transfer to.
  final PickOrganizer onPickOrganizer;

  /// Picks the coaches to add.
  final PickCoaches onPickCoaches;

  /// Whether the actions respond; the host turns it off while it saves.
  final bool enabled;

  @override
  State<EventStaffForm> createState() => EventStaffFormState();
}

/// State of [EventStaffForm]. Its values are
/// `{organizerNameId: String, coachNamesId: List<String>}`: the usernames of
/// the organizer and of the coaches the event keeps.
class EventStaffFormState extends State<EventStaffForm>
    with FormContract<EventStaffForm> {
  @override
  bool get focusFirstInvalid => false;

  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) => {
    EventFormFields.organizerNameId: EventStaffFormValues.organizerUsername(
      values,
    ),
    EventFormFields.coachNamesId: EventStaffFormValues.coachUsernames(values),
  };

  /// Whether the organizer or the coaches the event keeps differ from the
  /// initial ones, by username.
  @override
  bool get isDirty {
    final form = formKey.currentState;
    if (form == null) return false;
    final initial = form.initialValue;
    final current = form.value;
    return EventStaffFormValues.organizerUsername(initial) !=
            EventStaffFormValues.organizerUsername(current) ||
        !listEquals(
          EventStaffFormValues.coachUsernames(initial),
          EventStaffFormValues.coachUsernames(current),
        );
  }

  @override
  Widget build(BuildContext context) {
    return ShadForm(
      key: formKey,
      initialValue: {
        EventFormFields.organizerNameId: widget.initialOrganizer,
        EventFormFields.coachNamesId: widget.initialCoaches,
      },
      child: FormBody(
        error: formError,
        children: [
          LabeledFormRow(
            label: EventStaffFormStrings.organizerLabel,
            required: true,
            field: EventStaffOrganizerField(
              id: EventFormFields.organizerNameId,
              initialValue: widget.initialOrganizer,
              enabled: widget.enabled,
              validator: EventStaffFormValidators.organizer,
              onPick: widget.onPickOrganizer,
            ),
          ),
          LabeledFormRow(
            label: EventStaffFormStrings.coachesLabel,
            field: EventStaffCoachesField(
              id: EventFormFields.coachNamesId,
              initialValue: widget.initialCoaches,
              enabled: widget.enabled,
              onPick: widget.onPickCoaches,
            ),
          ),
        ],
      ),
    );
  }
}
