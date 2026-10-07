import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/one_off_schedule_data.dart';
import '../event_create/event_create_form_fields.dart' show EventVenueOption;
import '../event_schedule/one_off_schedule_fields.dart';
import '../event_schedule/two_column_grid.dart';
import '../form/labeled_form_row.dart';
import 'occurrence_reschedule_form_fields.dart';

/// Pure-UI form to reschedule a single camp occurrence (no SDK / no Riverpod).
///
/// A single day is, schedule-wise, a one-off session — date, start time,
/// duration — plus the venue it runs at. The form reuses
/// [OneOffScheduleFormField] for the schedule trio and a venue select; both
/// are pre-seeded from the occurrence's current values so an unmodified Save is
/// a no-op (`isDirty` stays `false`).
///
/// The form owns no buttons or dialog: the host drives it through a
/// `GlobalKey<OccurrenceRescheduleFormState>`. The host's Save calls
/// [OccurrenceRescheduleFormState.validate], which validates and returns the
/// flat form values (or `null` when invalid). The caller's adapter
/// (`cl_club_events` `occurrence_reschedule_form_helpers`) diffs those values
/// against the occurrence and sends only the changed fields to the SDK.
class OccurrenceRescheduleForm extends StatefulWidget {
  const OccurrenceRescheduleForm({
    required this.initialValues,
    required this.venues,
    this.enabled = true,
    super.key,
  });

  /// Seeded values: `{scheduleId: OneOffScheduleData, venueId: int}` — built by
  /// the host adapter from the occurrence's current start / duration / venue.
  final Map<String, dynamic> initialValues;

  /// Venues the form can move the occurrence to. Built by the host from the
  /// venue master provider.
  final List<EventVenueOption> venues;

  final bool enabled;

  @override
  State<OccurrenceRescheduleForm> createState() =>
      OccurrenceRescheduleFormState();
}

class OccurrenceRescheduleFormState extends State<OccurrenceRescheduleForm> {
  final formKey = GlobalKey<ShadFormState>();

  static const List<String> _trackedIds = [
    OccurrenceRescheduleFormFields.scheduleId,
    OccurrenceRescheduleFormFields.venueId,
  ];

  /// `true` once the schedule or venue diverges from the seeded values. A
  /// freshly mounted form is not dirty, so an unmodified Save closes without an
  /// SDK call.
  bool get isDirty {
    formKey.currentState?.save();
    final current = formKey.currentState?.value ?? const {};
    final initial = formKey.currentState?.initialValue ?? const {};
    for (final id in _trackedIds) {
      if (initial[id] != current[id]) return true;
    }
    return false;
  }

  /// Validates the schedule + venue fields; returns the flat form values
  /// (`{scheduleId: OneOffScheduleData, venueId: int}`) or `null` when invalid.
  Map<String, dynamic>? validate() {
    final form = formKey.currentState;
    if (form == null || !form.validate()) return null;
    form.save();
    return Map<String, dynamic>.from(form.value);
  }

  @override
  Widget build(BuildContext context) {
    return ShadForm(
      key: formKey,
      initialValue: widget.initialValues,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          OneOffScheduleFormField(
            id: OccurrenceRescheduleFormFields.scheduleId,
            initialValue:
                widget.initialValues[OccurrenceRescheduleFormFields.scheduleId]
                    as OneOffScheduleData,
            enabled: widget.enabled,
            validator: OneOffScheduleFormField.aggregateValidator,
          ),
          TwoColumnGrid(
            children: [
              LabeledFormRow(
                label: 'Venue',
                required: true,
                field: ShadSelectFormField<int>(
                  id: OccurrenceRescheduleFormFields.venueId,
                  initialValue:
                      widget.initialValues[OccurrenceRescheduleFormFields
                              .venueId]
                          as int?,
                  enabled: widget.enabled,
                  placeholder: const Text('Select a venue'),
                  validator: (value) =>
                      value == null ? 'Venue is required' : null,
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
              const SizedBox.shrink(),
            ],
          ),
        ],
      ),
    );
  }
}
