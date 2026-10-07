import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/programme_schedule_adjust_value.dart';
import '../../models/programme_schedule_data.dart';
import '../event_create/event_create_form_fields.dart' show EventVenueOption;
import '../form/labeled_form_row.dart';
import 'event_venue_select_field.dart';
import 'programme_schedule_adjust_form_validators.dart';
import 'programme_schedule_fields.dart';

/// Pure-UI editor that adjusts a programme's schedule from a chosen session
/// onward: the **From** session, then the weekdays, start time, duration
/// and sessions the create form uses ([ProgrammeScheduleFormField] without
/// its date range), and the venue.
///
/// SDK-free: the host seeds [initialValue], [fromOptions] and [venues] from
/// its models and drives the form through a
/// `GlobalKey<ProgrammeScheduleAdjustFormState>` —
/// [ProgrammeScheduleAdjustFormState.validate] from Save,
/// [ProgrammeScheduleAdjustFormState.isDirty] for no-op detection — and
/// shows a refusal with [ProgrammeScheduleAdjustFormState.showFormError].
class ProgrammeScheduleAdjustForm extends StatefulWidget {
  const ProgrammeScheduleAdjustForm({
    required this.initialValue,
    required this.fromOptions,
    required this.venues,
    this.enabled = true,
    super.key,
  });

  /// Field id of the From session picker.
  static const String fromId = 'from';

  /// Field id of the weekdays, start time, duration and sessions.
  static const String scheduleId = 'schedule';

  /// Field id of the venue picker.
  static const String venueId = 'venue';

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

  /// Whether the fields accept input.
  final bool enabled;

  @override
  State<ProgrammeScheduleAdjustForm> createState() =>
      ProgrammeScheduleAdjustFormState();
}

class ProgrammeScheduleAdjustFormState
    extends State<ProgrammeScheduleAdjustForm> {
  final formKey = GlobalKey<ShadFormState>();

  /// The form-level message of a refused save, shown inline.
  String? formError;

  /// The From session chosen now.
  late DateTime? from = widget.initialValue.from;

  ProgrammeScheduleAdjustValue get currentValue {
    final values = formKey.currentState?.value;
    if (values == null) return widget.initialValue;
    return ProgrammeScheduleAdjustValue(
      from: values[ProgrammeScheduleAdjustForm.fromId] as DateTime?,
      schedule:
          values[ProgrammeScheduleAdjustForm.scheduleId]
              as ProgrammeScheduleData? ??
          widget.initialValue.schedule,
      venueId: values[ProgrammeScheduleAdjustForm.venueId] as int?,
    );
  }

  /// Validates every field and returns the adjustment, else `null` (the
  /// fields say why).
  ProgrammeScheduleAdjustValue? validate() {
    final form = formKey.currentState;
    if (form == null || !form.saveAndValidate()) return null;
    setState(() => formError = null);
    return currentValue;
  }

  /// Whether the terms differ from the present schedule. Choosing another
  /// From session alone changes nothing.
  bool get isDirty {
    final value = currentValue;
    final initial = widget.initialValue;
    return value.schedule != initial.schedule ||
        value.venueId != initial.venueId;
  }

  /// Shows [message] as the inline form-level message, e.g. a clash the
  /// server refused the adjustment for.
  void showFormError(String message) => setState(() => formError = message);

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final initial = widget.initialValue;
    final chosen = from;
    final error = formError;
    return ShadForm(
      key: formKey,
      initialValue: {
        ProgrammeScheduleAdjustForm.fromId: initial.from,
        ProgrammeScheduleAdjustForm.scheduleId: initial.schedule,
        ProgrammeScheduleAdjustForm.venueId: initial.venueId,
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          LabeledFormRow(
            label: 'From',
            required: true,
            field: ShadSelectFormField<DateTime>(
              id: ProgrammeScheduleAdjustForm.fromId,
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
            id: ProgrammeScheduleAdjustForm.scheduleId,
            initialValue: initial.schedule,
            enabled: widget.enabled,
            showDateRange: false,
            validator: ProgrammeScheduleFormField.aggregateValidator,
          ),
          EventVenueSelectField(
            id: ProgrammeScheduleAdjustForm.venueId,
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
          if (error != null)
            Text(
              error,
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.destructive,
              ),
            ),
        ],
      ),
    );
  }
}
