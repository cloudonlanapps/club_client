import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/evaluation_view_sizes.dart';

/// The front matter of an evaluation or template in a card: a [title],
/// muted [facts] one per line, and [actions] beneath.
class EvaluationSummary extends StatelessWidget {
  /// A summary titled [title].
  const EvaluationSummary({
    required this.title,
    this.facts = const [],
    this.actions = const [],
    super.key,
  });

  /// The heading.
  final String title;

  /// Lines under the heading; empty ones are skipped.
  final List<String> facts;

  /// Buttons under the facts.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: EvaluationViewSizes.smallGap,
        children: [
          Text(title, style: theme.textTheme.h3),
          for (final fact in facts)
            if (fact.isNotEmpty) Text(fact, style: theme.textTheme.muted),
          if (actions.isNotEmpty)
            Wrap(
              spacing: EvaluationViewSizes.smallGap,
              runSpacing: EvaluationViewSizes.smallGap,
              children: actions,
            ),
        ],
      ),
    );
  }
}
