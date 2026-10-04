import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/camp_schedule_data.dart';
import 'camp_schedule_fields.dart';

/// Pure-UI editor for a camp event's schedule — start date, training-day
/// count, daily start time, duration, rest days and an optional named-session
/// split. Wraps the shared [CampScheduleFormField] in its own [ShadForm] so it
/// can be driven the same way as the other section editors
/// (`EventEligibilityForm`, `LocationEditForm`, …).
///
/// Host-agnostic and SDK-free: a caller (`cl_club_events`) embeds it and drives
/// it through a `GlobalKey<CampScheduleFormState>`, calling
/// [CampScheduleFormState.validate] from the Save action and reading
/// [CampScheduleFormState.isDirty] for no-op detection. The caller seeds
/// [initialValue] from the current event (the reverse adapter) and translates
/// the returned [CampScheduleData] back to the SDK reschedule call.
class CampScheduleForm extends StatefulWidget {
  const CampScheduleForm({
    required this.initialValue,
    this.enabled = true,
    super.key,
  });

  /// The camp schedule the form is seeded with — the event's current schedule
  /// when editing.
  final CampScheduleData initialValue;

  /// Whether the fields accept input.
  final bool enabled;

  @override
  State<CampScheduleForm> createState() => CampScheduleFormState();
}

class CampScheduleFormState extends State<CampScheduleForm> {
  /// Field id the single [CampScheduleFormField] registers under.
  static const String scheduleId = 'schedule';

  final formKey = GlobalKey<ShadFormState>();

  /// Validates the schedule and returns the assembled [CampScheduleData] when
  /// valid, else `null` (the field surfaces its own inline errors via
  /// [CampScheduleFormField.aggregateValidator] and its sub-fields).
  CampScheduleData? validate() {
    final form = formKey.currentState;
    if (form == null || !form.saveAndValidate()) return null;
    return form.value[scheduleId] as CampScheduleData?;
  }

  /// Whether the schedule differs from the value the form was seeded with.
  /// Relies on [CampScheduleData]'s value equality, so an unedited open is
  /// never dirty (an unmodified Save is a no-op).
  bool get isDirty {
    final form = formKey.currentState;
    if (form == null) return false;
    final current = form.value[scheduleId];
    return current is CampScheduleData && current != widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return ShadForm(
      key: formKey,
      initialValue: {scheduleId: widget.initialValue},
      child: CampScheduleFormField(
        id: scheduleId,
        initialValue: widget.initialValue,
        enabled: widget.enabled,
        validator: CampScheduleFormField.aggregateValidator,
      ),
    );
  }
}
