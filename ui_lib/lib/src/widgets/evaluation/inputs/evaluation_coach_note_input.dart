import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/evaluation_spacing.dart';
import '../../../constants/evaluation_strings.dart';
import 'evaluation_text_area.dart';

/// The coach note on one answer — its comment area — labelled, with a
/// reminder that the member reads it.
class EvaluationCoachNoteInput extends StatelessWidget {
  /// Edits [value].
  const EvaluationCoachNoteInput({
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// The note, or `null`.
  final String? value;

  /// Called with the new note; blank is `null`.
  final ValueChanged<String?> onChanged;

  /// Whether the note can change.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final text = ShadTheme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: EvaluationSpacing.smallGap,
      children: [
        Wrap(
          spacing: EvaluationSpacing.optionGap,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(EvaluationStrings.coachNote, style: text.small),
            Text(EvaluationStrings.coachNoteHint, style: text.muted),
          ],
        ),
        EvaluationTextArea(
          value: value,
          placeholder: EvaluationStrings.coachNotePlaceholder,
          enabled: enabled,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
