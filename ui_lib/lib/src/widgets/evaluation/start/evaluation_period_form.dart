import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/evaluation_spacing.dart';
import '../../../constants/evaluation_strings.dart';
import '../../../models/evaluation_start_options.dart';
import '../../../utils/evaluation_form_equality.dart';
import '../common/evaluation_form_focus.dart';
import 'evaluation_form_error.dart';
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
/// [EvaluationPeriodFormState.validate] from its Save action and reads
/// [EvaluationPeriodFormState.isDirty].
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

  /// Whether the event and the dates can change; the host turns it off
  /// while it saves.
  final bool enabled;

  @override
  State<EvaluationPeriodForm> createState() => EvaluationPeriodFormState();
}

/// State of [EvaluationPeriodForm]: the form and its form-level message.
class EvaluationPeriodFormState extends State<EvaluationPeriodForm>
    with EvaluationFormFocus<EvaluationPeriodForm> {
  /// The form.
  final GlobalKey<ShadFormState> formKey = GlobalKey<ShadFormState>();

  /// The period message (one date alone, out of order, ending after today,
  /// or the host's refusal), or `null`.
  String? formError;

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

  /// Validates the event and the period. Returns
  /// [EvaluationStartFormFields.eventId] (`null` for *General*),
  /// [EvaluationStartFormFields.periodStartId] and
  /// [EvaluationStartFormFields.periodEndId] when valid, else `null` with
  /// the message shown under the form.
  Map<String, dynamic>? validate() {
    final form = formKey.currentState;
    if (form == null || !form.saveAndValidate(focusOnInvalid: false)) {
      return null;
    }
    final start = form.value[EvaluationStartFormFields.periodStartId];
    final end = form.value[EvaluationStartFormFields.periodEndId];
    final error = EvaluationPeriodValidators.period(
      start as DateTime?,
      end as DateTime?,
    );
    setState(() => formError = error);
    if (error != null) return null;
    final event = form.value[EvaluationStartFormFields.eventId];
    return {
      EvaluationStartFormFields.eventId: (event as EvaluationStartEvent?)?.id,
      EvaluationStartFormFields.periodStartId: start,
      EvaluationStartFormFields.periodEndId: end,
    };
  }

  /// Shows [message] — the host's server refusal, e.g. a duplicate review
  /// or an ineligible member — under the form, as a period message is
  /// shown; it clears once the event or a date changes.
  void showRefusal(String message) => setState(() => formError = message);

  /// Whether the event or either date differs from the seeded ones.
  bool get isDirty {
    final form = formKey.currentState;
    if (form == null) return false;
    return !EvaluationFormEquality.mapsEqual(form.initialValue, form.value);
  }

  @override
  Widget build(BuildContext context) {
    final error = formError;
    return ShadForm(
      key: formKey,
      initialValue: {
        EvaluationStartFormFields.eventId: initialEventValue,
        EvaluationStartFormFields.periodStartId: widget.initialStart,
        EvaluationStartFormFields.periodEndId: widget.initialEnd,
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: EvaluationSpacing.fieldGap,
        children: [
          EvaluationStartSelect<EvaluationStartEvent>(
            id: EvaluationStartFormFields.eventId,
            label: EvaluationStrings.event,
            initialValue: initialEventValue,
            options: eventOptions,
            enabled: widget.enabled,
            onChanged: (_) {
              if (formError != null) setState(() => formError = null);
            },
          ),
          EvaluationPeriodFields(
            initialStart: widget.initialStart,
            initialEnd: widget.initialEnd,
            enabled: widget.enabled,
            onChanged: () {
              if (formError != null) setState(() => formError = null);
            },
          ),
          if (error != null) EvaluationFormError(message: error),
        ],
      ),
    );
  }
}
