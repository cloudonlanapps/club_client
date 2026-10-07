import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/form_spacing.dart';
import '../event_schedule/event_venue_select_field.dart';
import '../event_schedule/two_column_grid.dart';
import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../form/labeled_form_row.dart';
import 'event_create_form_defaults.dart';
import 'event_create_form_fields.dart';
import 'event_create_form_validators.dart';
import 'event_create_schedule_field.dart';

/// Pure-UI event creation form (no SDK / no Riverpod).
///
/// Gathers the minimal fields needed to create an event — title, visibility,
/// venue — plus the schedule, which is the focus: the matching schedule field
/// (`camp` / `programme` / `oneOff`) exposes its typed value through the
/// surrounding [ShadForm].
///
/// The form owns no title, buttons or dialog: the host drives it through a
/// `GlobalKey<EventCreateFormState>` ([FormContract]). Its Create action
/// calls `validate()` and hands the values to its adapter (`cl_club_events`
/// `event_create_form_helpers`), which maps them to the SDK create call;
/// `isDirty` drives the host's discard prompt, and `showErrors` puts back
/// what the server refuses.
class EventCreateForm extends StatefulWidget {
  const EventCreateForm({
    required this.eventType,
    required this.venues,
    this.initialValues,
    this.enabled = true,
    super.key,
  });

  /// The kind of event being created; decides the schedule field.
  final EventFormType eventType;

  /// The venues the event may be held at.
  final List<EventVenueOption> venues;

  /// What the form opens with; [defaultValues] of [eventType] when null.
  final Map<String, dynamic>? initialValues;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  /// Default values for a fresh event of [type]: empty title, public, no venue
  /// selected, and a sensible default schedule seeded from `now`.
  static Map<String, dynamic> defaultValues(
    EventFormType type, {
    DateTime? now,
  }) => EventCreateFormDefaults.values(type, now: now);

  @override
  State<EventCreateForm> createState() => EventCreateFormState();
}

/// State of [EventCreateForm]. Its values are the title, the visibility
/// ([EventFormVisibility]), the venue id and the schedule object of the
/// event type, under the ids of [EventCreateFormFields].
class EventCreateFormState extends State<EventCreateForm>
    with FormContract<EventCreateForm> {
  /// The form's own field ids. The schedule field's inputs register under
  /// generated ids in the same `ShadForm`; the schedule value already
  /// gathers every one of their edits.
  static const List<String> trackedIds = [
    EventCreateFormFields.titleId,
    EventCreateFormFields.visibilityId,
    EventCreateFormFields.venueId,
    EventCreateFormFields.scheduleId,
  ];

  /// What the form opened with.
  late final Map<String, dynamic> initial =
      widget.initialValues ?? EventCreateForm.defaultValues(widget.eventType);

  /// A venue must be selected before the event can be created.
  @override
  String? crossFieldError(Map<String, dynamic> values) =>
      EventCreateFormValidators.venue(
        values[EventCreateFormFields.venueId] as int?,
      );

  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) => {
    for (final id in trackedIds) id: values[id],
  };

  /// `true` once any tracked field diverges from the seeded initial values. A
  /// freshly mounted create form is not dirty.
  @override
  bool get isDirty {
    final form = formKey.currentState;
    if (form == null) return false;
    final current = form.value;
    return trackedIds.any(
      (id) => normalized(form.initialValue[id]) != normalized(current[id]),
    );
  }

  /// [value] as [isDirty] compares it: blank text reads as no value.
  Object? normalized(Object? value) =>
      value is String && value.trim().isEmpty ? null : value;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    return ShadForm(
      key: formKey,
      initialValue: initial,
      child: FormBody(
        error: formError,
        children: [
          LabeledFormRow(
            label: 'Title',
            required: true,
            field: ShadInputFormField(
              id: EventCreateFormFields.titleId,
              placeholder: Text('${widget.eventType.label} title'),
              keyboardType: TextInputType.text,
              enabled: enabled,
              validator: EventCreateFormValidators.title,
            ),
          ),
          TwoColumnGrid(
            runSpacing: FormSpacing.rowGap,
            children: [
              LabeledFormRow(
                label: 'Visibility',
                field: ShadSelectFormField<EventFormVisibility>(
                  id: EventCreateFormFields.visibilityId,
                  initialValue:
                      initial[EventCreateFormFields.visibilityId]
                          as EventFormVisibility? ??
                      EventFormVisibility.public,
                  enabled: enabled,
                  options: [
                    for (final v in EventFormVisibility.values)
                      ShadOption(value: v, child: Text(v.label)),
                  ],
                  selectedOptionBuilder: (context, value) => Text(value.label),
                ),
              ),
              EventVenueSelectField(
                id: EventCreateFormFields.venueId,
                venues: widget.venues,
                initialValue: initial[EventCreateFormFields.venueId] as int?,
                enabled: enabled,
              ),
            ],
          ),
          EventCreateScheduleField(
            eventType: widget.eventType,
            initialValue: initial[EventCreateFormFields.scheduleId],
            enabled: enabled,
          ),
        ],
      ),
    );
  }
}
