import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/camp_schedule_data.dart';
import '../../models/one_off_schedule_data.dart';
import '../../models/programme_schedule_data.dart';
import '../event_schedule/camp_schedule_fields.dart';
import '../event_schedule/labeled_form_row.dart';
import '../event_schedule/one_off_schedule_fields.dart';
import '../event_schedule/programme_schedule_fields.dart';
import '../event_schedule/two_column_grid.dart';
import 'event_create_form_fields.dart';
import 'event_create_form_validators.dart';

/// Pure-UI event creation form (no SDK / no Riverpod).
///
/// Gathers the minimal fields needed to create an event — title, visibility,
/// venue — plus the schedule, which is the focus: the matching schedule field
/// (`camp` / `programme` / `oneOff`) is mounted inside a card and exposes its
/// typed value through the surrounding [ShadForm].
///
/// The form owns no buttons or dialog (the host drives it through a
/// `GlobalKey<EventCreateFormState>`): the host's Save action calls
/// [EventCreateFormState.handleSubmit], which validates and hands the flat
/// form values to [onSubmit]. The caller's adapter
/// (`cl_club_events` `event_create_form_helpers`) maps those values to the SDK
/// create call. `isDirty` drives the host's discard prompt.
class EventCreateForm extends StatefulWidget {
  const EventCreateForm({
    required this.eventType,
    required this.venues,
    required this.onSubmit,
    this.title,
    this.initialValues,
    this.isSubmitting = false,
    super.key,
  });

  final EventFormType eventType;
  final List<EventVenueOption> venues;
  final Future<void> Function(Map<String, dynamic> values) onSubmit;
  final String? title;
  final Map<String, dynamic>? initialValues;
  final bool isSubmitting;

  /// Default values for a fresh event of [type]: empty title, public, no venue
  /// selected, and a sensible default schedule seeded from `now`.
  static Map<String, dynamic> defaultValues(
    EventFormType type, {
    DateTime? now,
  }) {
    now ??= DateTime.now();
    return {
      EventCreateFormFields.titleId: '',
      EventCreateFormFields.visibilityId: EventFormVisibility.public,
      EventCreateFormFields.venueId: null,
      EventCreateFormFields.scheduleId: _defaultSchedule(type, now),
    };
  }

  static Object _defaultSchedule(EventFormType type, DateTime now) {
    switch (type) {
      case EventFormType.programme:
        // The next whole hour, dated by that hour, so a form opened late in
        // the evening does not start the series at midnight already past.
        final next = now.add(const Duration(hours: 1));
        return ProgrammeScheduleData(
          startDate: DateTime(next.year, next.month, next.day),
          sessionStartTime: ShadTimeOfDay(
            hour: next.hour,
            minute: 0,
            second: 0,
          ),
        );
      case EventFormType.camp:
        // Create seed for a new camp: starts tomorrow, 5 training days, 6:00am,
        // 1.5h per day.
        return CampScheduleData(
          startDate: now.add(const Duration(days: 1)),
          trainingDays: 5,
          sessionStartTime: const ShadTimeOfDay(hour: 6, minute: 0, second: 0),
          durationMinutes: 90,
        );
      case EventFormType.oneOff:
        final start = now.add(const Duration(hours: 1));
        return OneOffScheduleData(
          date: DateTime(start.year, start.month, start.day),
          startTime: ShadTimeOfDay(
            hour: start.hour,
            minute: start.minute,
            second: 0,
          ),
        );
    }
  }

  @override
  State<EventCreateForm> createState() => EventCreateFormState();
}

class EventCreateFormState extends State<EventCreateForm> {
  final formKey = GlobalKey<ShadFormState>();
  late final Map<String, dynamic> _initial;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _initial =
        widget.initialValues ?? EventCreateForm.defaultValues(widget.eventType);
  }

  /// The form's own field ids. The schedule field's internal inputs register
  /// auto-generated ids into the same `ShadForm`, so [isDirty] compares only
  /// these — the `scheduleId` value already aggregates every schedule edit.
  static const List<String> _trackedIds = [
    EventCreateFormFields.titleId,
    EventCreateFormFields.visibilityId,
    EventCreateFormFields.venueId,
    EventCreateFormFields.scheduleId,
  ];

  /// `true` once any tracked field diverges from the seeded initial values. A
  /// freshly mounted create form is not dirty.
  bool get isDirty {
    formKey.currentState?.save();
    final current = formKey.currentState?.value ?? const {};
    final initial = formKey.currentState?.initialValue ?? const {};
    for (final id in _trackedIds) {
      if (_normalize(initial[id]) != _normalize(current[id])) return true;
    }
    return false;
  }

  Object? _normalize(Object? value) {
    if (value is String && value.trim().isEmpty) return null;
    return value;
  }

  /// Validate every field (title, venue, and the schedule field's aggregate
  /// rule), then hand the flat form values to the host's `onSubmit`. Surfaces
  /// the venue requirement as an inline form-level message rather than a toast.
  Future<void> handleSubmit() async {
    final form = formKey.currentState;
    if (form == null || !form.validate()) return;
    form.save();
    final values = form.value;

    final venueError = EventCreateFormValidators.venue(
      values[EventCreateFormFields.venueId] as int?,
    );
    if (venueError != null) {
      setState(() => _formError = venueError);
      return;
    }
    setState(() => _formError = null);
    await widget.onSubmit(values);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final enabled = !widget.isSubmitting;

    return ShadForm(
      key: formKey,
      initialValue: _initial,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          if (widget.title != null)
            Text(widget.title!, style: theme.textTheme.h4),
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
            children: [
              LabeledFormRow(
                label: 'Visibility',
                field: ShadSelectFormField<EventFormVisibility>(
                  id: EventCreateFormFields.visibilityId,
                  initialValue:
                      _initial[EventCreateFormFields.visibilityId]
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
              LabeledFormRow(
                label: 'Venue',
                required: true,
                field: ShadSelectFormField<int>(
                  id: EventCreateFormFields.venueId,
                  initialValue: _initial[EventCreateFormFields.venueId] as int?,
                  enabled: enabled,
                  placeholder: const Text('Select a venue'),
                  options: [
                    for (final venue in widget.venues)
                      ShadOption(value: venue.id, child: Text(venue.name)),
                  ],
                  selectedOptionBuilder: (context, value) => Text(
                    widget.venues
                        .firstWhere(
                          (venue) => venue.id == value,
                          orElse: () =>
                              EventVenueOption(id: value, name: '#$value'),
                        )
                        .name,
                  ),
                ),
              ),
            ],
          ),
          _scheduleField(),
          if (_formError != null)
            Text(
              _formError!,
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.destructive,
              ),
            ),
        ],
      ),
    );
  }

  Widget _scheduleField() {
    final enabled = !widget.isSubmitting;
    final initial = _initial[EventCreateFormFields.scheduleId];
    switch (widget.eventType) {
      case EventFormType.oneOff:
        return OneOffScheduleFormField(
          id: EventCreateFormFields.scheduleId,
          initialValue: initial as OneOffScheduleData,
          enabled: enabled,
          validator: OneOffScheduleFormField.aggregateValidator,
        );
      case EventFormType.camp:
        return CampScheduleFormField(
          id: EventCreateFormFields.scheduleId,
          initialValue: initial as CampScheduleData,
          enabled: enabled,
          validator: CampScheduleFormField.aggregateValidator,
        );
      case EventFormType.programme:
        return ProgrammeScheduleFormField(
          id: EventCreateFormFields.scheduleId,
          initialValue: initial as ProgrammeScheduleData,
          enabled: enabled,
          validator: ProgrammeScheduleFormField.aggregateValidator,
        );
    }
  }
}
