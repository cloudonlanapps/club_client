import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/programme_schedule_adjust_value.dart';
import '../../models/programme_schedule_data.dart';
import '../event_create/event_create_form_fields.dart' show EventVenueOption;
import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../form/labeled_form_row.dart';
import 'event_venue_select_field.dart';
import 'programme_schedule_adjust_form_fields.dart';
import 'programme_schedule_adjust_form_validators.dart';
import 'programme_schedule_fields.dart';

/// Pure-UI editor that adjusts a programme's schedule from a chosen session
/// onward: the **From** session, then the weekdays, start time, duration
/// and sessions the create form uses ([ProgrammeScheduleFormField] without
/// its date range), and the venue.
///
/// SDK-free: the host seeds [initialValue], [fromOptions] and [venues] from
/// its models and drives the form through a
/// `GlobalKey<ProgrammeScheduleAdjustFormState>` ([FormContract]); a refusal
/// goes back on the field it is about, or inline, with `showErrors`.
class ProgrammeScheduleAdjustForm extends StatefulWidget {
  const ProgrammeScheduleAdjustForm({
    required this.initialValue,
    required this.fromOptions,
    required this.venues,
    this.enabled = true,
    super.key,
  });

  /// How a From session is written in the picker and in [effectLine].
  static final DateFormat fromFormat = DateFormat('EEE d MMM y, HH:mm');

  /// What saving does, for the session starting at [from].
  static String effectLine(DateTime from) =>
      'Sessions before ${fromFormat.format(from.toLocal())} keep the '
      'present schedule; sessions from it follow the new one.';

  /// The present schedule, and the From session chosen when the form opens.
  final ProgrammeScheduleAdjustValue initialValue;

  /// The session starts the new schedule may begin at: the upcoming ones of
  /// the present schedule, soonest first.
  final List<DateTime> fromOptions;

  /// The venues the programme may move to.
  final List<EventVenueOption> venues;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  @override
  State<ProgrammeScheduleAdjustForm> createState() =>
      ProgrammeScheduleAdjustFormState();
}

/// State of [ProgrammeScheduleAdjustForm]. Its values are the From session
/// (`DateTime`), the schedule (`ProgrammeScheduleData`) and the venue id,
/// under the ids of [ProgrammeScheduleAdjustFormFields].
class ProgrammeScheduleAdjustFormState
    extends State<ProgrammeScheduleAdjustForm>
    with FormContract<ProgrammeScheduleAdjustForm> {
  @override
  bool get focusFirstInvalid => false;

  /// The From session chosen now.
  late DateTime? from = widget.initialValue.from;

  /// The adjustment as the form holds it now.
  ProgrammeScheduleAdjustValue get currentValue {
    final values = formKey.currentState?.value;
    if (values == null) return widget.initialValue;
    return ProgrammeScheduleAdjustValue(
      from: values[ProgrammeScheduleAdjustFormFields.fromId] as DateTime?,
      schedule:
          values[ProgrammeScheduleAdjustFormFields.scheduleId]
              as ProgrammeScheduleData? ??
          widget.initialValue.schedule,
      venueId: values[ProgrammeScheduleAdjustFormFields.venueId] as int?,
    );
  }

  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) {
    final value = currentValue;
    return {
      ProgrammeScheduleAdjustFormFields.fromId: value.from,
      ProgrammeScheduleAdjustFormFields.scheduleId: value.schedule,
      ProgrammeScheduleAdjustFormFields.venueId: value.venueId,
    };
  }

  /// Whether the terms differ from the present schedule. Choosing another
  /// From session alone changes nothing.
  @override
  bool get isDirty {
    final value = currentValue;
    final initial = widget.initialValue;
    return value.schedule != initial.schedule ||
        value.venueId != initial.venueId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final initial = widget.initialValue;
    final chosen = from;
    return ShadForm(
      key: formKey,
      initialValue: {
        ProgrammeScheduleAdjustFormFields.fromId: initial.from,
        ProgrammeScheduleAdjustFormFields.scheduleId: initial.schedule,
        ProgrammeScheduleAdjustFormFields.venueId: initial.venueId,
      },
      child: FormBody(
        error: formError,
        children: [
          LabeledFormRow(
            label: 'From',
            required: true,
            field: ShadSelectFormField<DateTime>(
              id: ProgrammeScheduleAdjustFormFields.fromId,
              initialValue: initial.from,
              enabled: widget.enabled,
              placeholder: const Text('Pick a session'),
              validator: (value) => ProgrammeScheduleAdjustFormValidators.from(
                value,
                widget.fromOptions,
              ),
              options: [
                for (final option in widget.fromOptions)
                  ShadOption(
                    value: option,
                    child: Text(
                      ProgrammeScheduleAdjustForm.fromFormat.format(
                        option.toLocal(),
                      ),
                    ),
                  ),
              ],
              selectedOptionBuilder: (context, value) => Text(
                ProgrammeScheduleAdjustForm.fromFormat.format(value.toLocal()),
              ),
              onChanged: (value) => setState(() => from = value),
            ),
          ),
          ProgrammeScheduleFormField(
            id: ProgrammeScheduleAdjustFormFields.scheduleId,
            initialValue: initial.schedule,
            enabled: widget.enabled,
            showDateRange: false,
            validator: ProgrammeScheduleFormField.aggregateValidator,
          ),
          EventVenueSelectField(
            id: ProgrammeScheduleAdjustFormFields.venueId,
            venues: widget.venues,
            initialValue: initial.venueId,
            enabled: widget.enabled,
            validator: ProgrammeScheduleAdjustFormValidators.venue,
          ),
          if (chosen != null)
            Text(
              ProgrammeScheduleAdjustForm.effectLine(chosen),
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
            ),
        ],
      ),
    );
  }
}
