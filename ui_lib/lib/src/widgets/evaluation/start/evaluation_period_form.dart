import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/evaluation_strings.dart';
import '../../../models/evaluation_start_options.dart';
import '../common/evaluation_form_body.dart';
import '../common/evaluation_form_contract.dart';
import '../common/evaluation_form_focus.dart';
import 'evaluation_period_fields.dart';
import 'evaluation_period_validators.dart';
import 'evaluation_start_form.dart';
import 'evaluation_start_form_fields.dart';
import 'evaluation_start_select.dart';

/// Pure-UI section editor of an evaluation's Review Period (no SDK, no
/// Riverpod): the event — *General* or one of [events] — and two optional
/// dates, both or neither, ending by today.
///
/// Owns no buttons: the host (an `EditableSectionCard`) calls
/// [EvaluationPeriodFormState.validate] from its Save action, reads
/// [EvaluationPeriodFormState.isDirty] and shows a server refusal with
/// [EvaluationPeriodFormState.showErrors].
class EvaluationPeriodForm extends StatefulWidget {
  /// Edits the event and the period seeded with [initialValues].
  const EvaluationPeriodForm({
    this.events = const [],
    this.initialValues = const {},
    this.enabled = true,
    super.key,
  });

  /// The events to choose from, besides *General*.
  final List<EvaluationStartChoice> events;

  /// Initial values, keyed by the ids of [EvaluationStartFormFields]: under
  /// [EvaluationStartFormFields.eventId] the event, an
  /// [EvaluationStartChoice] (*General* when left out), offered even when
  /// it is not among [events]; under
  /// [EvaluationStartFormFields.periodStartId] and
  /// [EvaluationStartFormFields.periodEndId] the first and the last day,
  /// each a local `DateTime` (none when left out).
  final Map<String, dynamic> initialValues;

  /// Whether the fields can change (off while the host saves).
  final bool enabled;

  @override
  State<EvaluationPeriodForm> createState() => EvaluationPeriodFormState();
}

/// State of [EvaluationPeriodForm]: the form and its form-level message.
class EvaluationPeriodFormState extends State<EvaluationPeriodForm>
    with
        EvaluationFormContract<EvaluationPeriodForm>,
        EvaluationFormFocus<EvaluationPeriodForm> {
  // Selects and date pickers have no input to focus.
  @override
  bool get focusFirstInvalid => false;

  /// The seeded event, or `null` for *General*.
  EvaluationStartChoice? get initialEvent =>
      widget.initialValues[EvaluationStartFormFields.eventId]
          as EvaluationStartChoice?;

  /// The seeded first day.
  DateTime? get initialStart =>
      widget.initialValues[EvaluationStartFormFields.periodStartId]
          as DateTime?;

  /// The seeded last day.
  DateTime? get initialEnd =>
      widget.initialValues[EvaluationStartFormFields.periodEndId] as DateTime?;

  /// The seeded event as the select holds it.
  EvaluationStartEvent get initialEventValue => switch (initialEvent) {
    final e? => (id: e.id, label: e.label),
    null => EvaluationStartForm.general,
  };

  /// The event select's choices: *General*, the seeded event when it is not
  /// among the offered ones, then the offered events.
  List<(EvaluationStartEvent, String)> get eventOptions {
    final offered = widget.events;
    final current = initialEvent;
    return [
      const (EvaluationStartForm.general, EvaluationStrings.general),
      if (current != null && !offered.any((e) => e.id == current.id))
        ((id: current.id, label: current.label), current.label),
      for (final e in offered) ((id: e.id, label: e.label), e.label),
    ];
  }

  /// The period message: one date alone, out of order, or ending after
  /// today.
  @override
  String? crossFieldError(Map<String, dynamic> values) =>
      EvaluationPeriodValidators.period(
        values[EvaluationStartFormFields.periodStartId] as DateTime?,
        values[EvaluationStartFormFields.periodEndId] as DateTime?,
      );

  /// [EvaluationStartFormFields.eventId] as the event's id (`null` for
  /// *General*), with [EvaluationStartFormFields.periodStartId] and
  /// [EvaluationStartFormFields.periodEndId].
  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) {
    final event = values[EvaluationStartFormFields.eventId];
    return {
      EvaluationStartFormFields.eventId: (event as EvaluationStartEvent?)?.id,
      EvaluationStartFormFields.periodStartId:
          values[EvaluationStartFormFields.periodStartId],
      EvaluationStartFormFields.periodEndId:
          values[EvaluationStartFormFields.periodEndId],
    };
  }

  @override
  Widget build(BuildContext context) {
    return ShadForm(
      key: formKey,
      initialValue: {
        EvaluationStartFormFields.eventId: initialEventValue,
        EvaluationStartFormFields.periodStartId: initialStart,
        EvaluationStartFormFields.periodEndId: initialEnd,
      },
      child: EvaluationFormBody(
        error: formError,
        children: [
          EvaluationStartSelect<EvaluationStartEvent>(
            id: EvaluationStartFormFields.eventId,
            label: EvaluationStrings.event,
            initialValue: initialEventValue,
            enabled: widget.enabled,
            options: eventOptions,
          ),
          EvaluationPeriodFields(
            initialStart: initialStart,
            initialEnd: initialEnd,
            enabled: widget.enabled,
          ),
        ],
      ),
    );
  }
}
