import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/evaluation_spacing.dart';
import '../../../constants/evaluation_strings.dart';
import '../../../models/evaluation_item_value.dart';
import 'evaluation_markdown_text.dart';

/// A question's text, with "*" when required and a plain-text marker when
/// private.
class EvaluationQuestionHeader extends StatelessWidget {
  /// Heads [item].
  const EvaluationQuestionHeader({required this.item, super.key});

  /// The question.
  final EvaluationItemValue item;

  @override
  Widget build(BuildContext context) {
    final text = ShadTheme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: EvaluationSpacing.smallGap,
          children: [
            Flexible(
              child: EvaluationMarkdownText(data: item.text, style: text.large),
            ),
            if (item.isRequired)
              Text(EvaluationStrings.requiredMarker, style: text.large),
          ],
        ),
        if (item.isPrivate)
          Text(EvaluationStrings.privateMarker, style: text.muted),
      ],
    );
  }
}
