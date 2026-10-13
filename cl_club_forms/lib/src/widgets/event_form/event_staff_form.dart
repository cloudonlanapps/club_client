import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/event_staff_member.dart';
import '../../models/event_staff_pickers.dart';
import '../event_schedule/programme_from_session_field.dart';
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
/// A programme changes its staffing from a session onward, so its editor
/// also asks for that session: given [fromOptions], the form shows a
/// required **From** select over them and says what saving does.
///
/// The host supplies the candidate pickers ([onPickOrganizer] /
/// [onPickCoaches]) and drives the form through a
/// `GlobalKey<EventStaffFormState>` ([FormContract]).
class EventStaffForm extends StatefulWidget {
  const EventStaffForm({
    required this.initialValues,
    required this.onPickOrganizer,
    required this.onPickCoaches,
    this.fromOptions,
    this.enabled = true,
    super.key,
  });

  /// Initial values: the event's organizer, an [EventStaffMember], under
  /// [EventFormFields.organizerNameId] (none when left out), and its
  /// coaches, a list of them, under [EventFormFields.coachNamesId] (none
  /// when left out). With [fromOptions], the session chosen when the form
  /// opens, a `DateTime`, under [EventFormFields.effectiveFromId].
  final Map<String, dynamic> initialValues;

  /// The session starts a programme's change may take effect from: the
  /// upcoming ones of its present schedule, soonest first. `null` for a
  /// camp or a one-off, whose staffing changes at once: no From is asked.
  final List<DateTime>? fromOptions;

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
/// the organizer and of the coaches the event keeps; a programme's also
/// hold `effectiveFromId`, the From session as a `DateTime`.
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
    if (widget.fromOptions != null)
      EventFormFields.effectiveFromId:
          values[EventFormFields.effectiveFromId] as DateTime?,
  };

  /// The From session chosen now; null when none is asked or chosen.
  late DateTime? from = initialFrom;

  /// The From session the form opens with.
  DateTime? get initialFrom =>
      widget.initialValues[EventFormFields.effectiveFromId] as DateTime?;

  /// Whether the organizer or the coaches the event keeps differ from the
  /// initial ones, by username. Choosing another From session alone changes
  /// nothing.
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

  /// The organizer the form opens with; null when the event has none.
  EventStaffMember? get initialOrganizer =>
      widget.initialValues[EventFormFields.organizerNameId]
          as EventStaffMember?;

  /// The coaches the form opens with.
  List<EventStaffMember> get initialCoaches => [
    for (final coach
        in (widget.initialValues[EventFormFields.coachNamesId]
                as List<dynamic>?) ??
            const <dynamic>[])
      coach as EventStaffMember,
  ];

  @override
  Widget build(BuildContext context) {
    final organizer = initialOrganizer;
    final coaches = initialCoaches;
    final fromOptions = widget.fromOptions;
    final chosen = from;
    final theme = ShadTheme.of(context);
    return ShadForm(
      key: formKey,
      initialValue: {
        EventFormFields.organizerNameId: organizer,
        EventFormFields.coachNamesId: coaches,
        if (fromOptions != null) EventFormFields.effectiveFromId: initialFrom,
      },
      child: FormBody(
        error: formError,
        children: [
          LabeledFormRow(
            label: EventStaffFormStrings.organizerLabel,
            required: true,
            field: EventStaffOrganizerField(
              id: EventFormFields.organizerNameId,
              initialValue: organizer,
              enabled: widget.enabled,
              validator: EventStaffFormValidators.organizer,
              onPick: widget.onPickOrganizer,
            ),
          ),
          LabeledFormRow(
            label: EventStaffFormStrings.coachesLabel,
            field: EventStaffCoachesField(
              id: EventFormFields.coachNamesId,
              initialValue: coaches,
              enabled: widget.enabled,
              onPick: widget.onPickCoaches,
            ),
          ),
          if (fromOptions != null)
            LabeledFormRow(
              label: ProgrammeFromSessionField.label,
              required: true,
              field: ProgrammeFromSessionField(
                id: EventFormFields.effectiveFromId,
                options: fromOptions,
                initialValue: initialFrom,
                enabled: widget.enabled,
                validator: (value) =>
                    EventStaffFormValidators.from(value, fromOptions),
                onChanged: (value) => setState(() => from = value),
              ),
            ),
          if (fromOptions != null && chosen != null)
            Text(
              EventStaffFormStrings.effectLine(
                ProgrammeFromSessionField.textOf(chosen),
              ),
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
            ),
        ],
      ),
    );
  }
}
