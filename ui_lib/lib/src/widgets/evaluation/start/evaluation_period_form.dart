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
  /// Edits the event seeded with [initialEvent] and the period seeded with
  /// [initialStart] and [initialEnd].
  const EvaluationPeriodForm({
    this.events = const [],
    this.initialEvent,
    this.initialStart,
    this.initialEnd,
    this.enabled = true,
    super.key,
  });

  /// The events to choose from, besides *General*.
  final List<EvaluationStartChoice> events;

  /// The seeded event, or `null` for *General*. Offered even when it is not
  /// among [events].
  final EvaluationStartChoice? initialEvent;

  /// The seeded first day.
  final DateTime? initialStart;

  /// The seeded last day.
  final DateTime? initialEnd;

  /// Whether the fields can change (off while the host saves).
  final bool enabled;

  @override
  State<EvaluationPeriodForm> createState() => EvaluationPeriodFormState();
}

/// State of [EvaluationPeriodForm]: the form and its form-level message.
class EvaluationPeriodFormState extends State<EvaluationPeriodForm>
    with
        EvaluationFormFocus<EvaluationPeriodForm>,
        EvaluationFormContract<EvaluationPeriodForm> {
  // Selects and date pickers have no input to focus.
  @override
  bool get focusFirstInvalid => false;

  /// The seeded event as the select holds it.
  EvaluationStartEvent get initialEventValue => switch (widget.initialEvent) {
    final e? => (id: e.id, label: e.label),
    null => EvaluationStartForm.general,
  };

  /// The event select's choices: *General*, the seeded event when it is not
  /// among the offered ones, then the offered events.
  List<(EvaluationStartEvent, String)> get eventOptions {
    final offered = widget.events;
    final current = widget.initialEvent;
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
        EvaluationStartFormFields.periodStartId: widget.initialStart,
        EvaluationStartFormFields.periodEndId: widget.initialEnd,
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
            // A changed event or date clears the message about them.
            onChanged: (_) => setFormError(null),
          ),
          EvaluationPeriodFields(
            initialStart: widget.initialStart,
            initialEnd: widget.initialEnd,
            enabled: widget.enabled,
            onChanged: () => setFormError(null),
          ),
        ],
      ),
    );
  }
}
