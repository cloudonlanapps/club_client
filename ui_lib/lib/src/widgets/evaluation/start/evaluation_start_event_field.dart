import 'package:flutter/widgets.dart';

import '../../../constants/evaluation_strings.dart';
import '../../../models/evaluation_start_options.dart';
import 'evaluation_start_fixed_value.dart';
import 'evaluation_start_form.dart';
import 'evaluation_start_form_fields.dart';
import 'evaluation_start_select.dart';

/// The event row of [EvaluationStartForm]: the event its host fixed, shown
/// read-only, or a select of *General* and the chosen member's events.
class EvaluationStartEventField extends StatelessWidget {
  /// The event row offering [options] besides *General*.
  const EvaluationStartEventField({
    required this.fixedEvent,
    required this.memberUsername,
    required this.options,
    required this.enabled,
    super.key,
  });

  /// The event, when the host fixes it.
  final EvaluationStartChoice? fixedEvent;

  /// The chosen member's username, or `null` before a choice.
  final String? memberUsername;

  /// The events offered for the chosen member.
  final List<EvaluationStartChoice> options;

  /// Whether the select can change.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (fixedEvent case final e?) {
      return EvaluationStartFixedValue(
        label: EvaluationStrings.event,
        value: e.label,
      );
    }
    return EvaluationStartSelect<EvaluationStartEvent>(
      // A new member rebuilds the field, back to General.
      key: ValueKey<String?>(memberUsername),
      id: EvaluationStartFormFields.eventId,
      label: EvaluationStrings.event,
      initialValue: EvaluationStartForm.general,
      enabled: enabled,
      options: [
        const (
          EvaluationStartForm.general,
          EvaluationStrings.general,
        ),
        for (final e in options) ((id: e.id, label: e.label), e.label),
      ],
    );
  }
}
