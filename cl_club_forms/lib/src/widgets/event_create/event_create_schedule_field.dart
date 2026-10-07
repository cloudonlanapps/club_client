import 'package:flutter/widgets.dart';

import '../../models/camp_schedule_data.dart';
import '../../models/one_off_schedule_data.dart';
import '../../models/programme_schedule_data.dart';
import '../event_schedule/camp_schedule_fields.dart';
import '../event_schedule/one_off_schedule_fields.dart';
import '../event_schedule/programme_schedule_fields.dart';
import 'event_create_form_fields.dart';

/// The schedule field of the create form: the field cluster of
/// [eventType], registered under [EventCreateFormFields.scheduleId], whose
/// value is that type's schedule object.
class EventCreateScheduleField extends StatelessWidget {
  const EventCreateScheduleField({
    required this.eventType,
    required this.initialValue,
    this.enabled = true,
    super.key,
  });

  /// The kind of event being created; decides the cluster.
  final EventFormType eventType;

  /// The schedule the cluster opens with: the schedule object of
  /// [eventType].
  final Object? initialValue;

  /// Whether the cluster's inputs respond.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return switch (eventType) {
      EventFormType.oneOff => OneOffScheduleFormField(
        id: EventCreateFormFields.scheduleId,
        initialValue: initialValue as OneOffScheduleData?,
        enabled: enabled,
        validator: OneOffScheduleFormField.aggregateValidator,
      ),
      EventFormType.camp => CampScheduleFormField(
        id: EventCreateFormFields.scheduleId,
        initialValue: initialValue as CampScheduleData?,
        enabled: enabled,
        validator: CampScheduleFormField.aggregateValidator,
      ),
      EventFormType.programme => ProgrammeScheduleFormField(
        id: EventCreateFormFields.scheduleId,
        initialValue: initialValue as ProgrammeScheduleData?,
        enabled: enabled,
        validator: ProgrammeScheduleFormField.aggregateValidator,
      ),
    };
  }
}
