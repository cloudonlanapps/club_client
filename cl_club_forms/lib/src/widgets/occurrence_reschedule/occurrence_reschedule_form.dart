import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/form_spacing.dart';
import '../../models/one_off_schedule_data.dart';
import '../event_create/event_create_form_fields.dart' show EventVenueOption;
import '../event_schedule/event_venue_select_field.dart';
import '../event_schedule/one_off_schedule_fields.dart';
import '../event_schedule/two_column_grid.dart';
import '../form/form_body.dart';
import '../form/form_contract.dart';
import 'occurrence_reschedule_form_fields.dart';
import 'occurrence_reschedule_form_validators.dart';

/// Pure-UI form to reschedule a single camp occurrence (no SDK / no Riverpod).
///
/// A single day is, schedule-wise, a one-off session — date, start time,
/// duration — plus the venue it runs at. The form reuses
/// [OneOffScheduleFormField] for the schedule trio and a venue select; both
/// are pre-seeded from the occurrence's current values so an unmodified Save is
/// a no-op (`isDirty` stays `false`).
///
/// The form owns no buttons or dialog: the host drives it through a
/// `GlobalKey<OccurrenceRescheduleFormState>` ([FormContract]). The caller's
/// adapter (`cl_club_events` `occurrence_reschedule_form_helpers`) diffs the
/// values against the occurrence and sends only the changed fields to the SDK.
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

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  @override
  State<OccurrenceRescheduleForm> createState() =>
      OccurrenceRescheduleFormState();
}

/// State of [OccurrenceRescheduleForm]. Its values are
/// `{scheduleId: OneOffScheduleData, venueId: int}`, under the ids of
/// [OccurrenceRescheduleFormFields].
class OccurrenceRescheduleFormState extends State<OccurrenceRescheduleForm>
    with FormContract<OccurrenceRescheduleForm> {
  @override
  bool get focusFirstInvalid => false;

  /// The form's own field ids. The schedule field's inputs register under
  /// generated ids in the same `ShadForm`; the schedule value already
  /// gathers every one of their edits.
  static const List<String> trackedIds = [
    OccurrenceRescheduleFormFields.scheduleId,
    OccurrenceRescheduleFormFields.venueId,
  ];

  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) => {
    for (final id in trackedIds) id: values[id],
  };

  /// `true` once the schedule or venue diverges from the seeded values. A
  /// freshly mounted form is not dirty, so an unmodified Save closes without
  /// an SDK call.
  @override
  bool get isDirty {
    final form = formKey.currentState;
    if (form == null) return false;
    final current = form.value;
    final initial = form.initialValue;
    return trackedIds.any((id) => initial[id] != current[id]);
  }

  @override
  Widget build(BuildContext context) {
    return ShadForm(
      key: formKey,
      initialValue: widget.initialValues,
      child: FormBody(
        error: formError,
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
            runSpacing: FormSpacing.rowGap,
            children: [
              EventVenueSelectField(
                id: OccurrenceRescheduleFormFields.venueId,
                venues: widget.venues,
                initialValue:
                    widget.initialValues[OccurrenceRescheduleFormFields.venueId]
                        as int?,
                enabled: widget.enabled,
                validator: OccurrenceRescheduleFormValidators.venue,
              ),
              const SizedBox.shrink(),
            ],
          ),
        ],
      ),
    );
  }
}
