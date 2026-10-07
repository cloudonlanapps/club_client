import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/camp_schedule_data.dart';
import '../form/form_body.dart';
import '../form/form_contract.dart';
import 'camp_schedule_fields.dart';
import 'camp_schedule_form_fields.dart';

/// Pure-UI editor for a camp event's schedule — start date, training-day
/// count, daily start time, duration, rest days and an optional named-session
/// split. Wraps the shared [CampScheduleFormField] in its own [ShadForm] so it
/// can be driven the same way as the other section editors.
///
/// Host-agnostic and SDK-free: a caller (`cl_club_events`) embeds it and
/// drives it through a `GlobalKey<CampScheduleFormState>` ([FormContract]).
/// The caller seeds [initialValue] from the current event (the reverse
/// adapter) and translates the returned [CampScheduleData] back to the SDK
/// reschedule call.
class CampScheduleForm extends StatefulWidget {
  const CampScheduleForm({
    required this.initialValue,
    this.enabled = true,
    super.key,
  });

  /// The camp schedule the form is seeded with — the event's current schedule
  /// when editing.
  final CampScheduleData initialValue;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  @override
  State<CampScheduleForm> createState() => CampScheduleFormState();
}

/// State of [CampScheduleForm]. Its values are
/// `{CampScheduleFormFields.scheduleId: CampScheduleData}`; the field shows
/// its own inline errors ([CampScheduleFormField.aggregateValidator] and its
/// inputs).
class CampScheduleFormState extends State<CampScheduleForm>
    with FormContract<CampScheduleForm> {
  @override
  bool get focusFirstInvalid => false;

  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) => {
    CampScheduleFormFields.scheduleId:
        values[CampScheduleFormFields.scheduleId] as CampScheduleData,
  };

  /// Whether the schedule differs from the value the form was seeded with.
  /// Relies on [CampScheduleData]'s value equality, so an unedited open is
  /// never dirty (an unmodified Save is a no-op).
  @override
  bool get isDirty {
    final form = formKey.currentState;
    if (form == null) return false;
    final current = form.value[CampScheduleFormFields.scheduleId];
    return current is CampScheduleData && current != widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return ShadForm(
      key: formKey,
      initialValue: {CampScheduleFormFields.scheduleId: widget.initialValue},
      child: FormBody(
        error: formError,
        children: [
          CampScheduleFormField(
            id: CampScheduleFormFields.scheduleId,
            initialValue: widget.initialValue,
            enabled: widget.enabled,
            validator: CampScheduleFormField.aggregateValidator,
          ),
        ],
      ),
    );
  }
}
