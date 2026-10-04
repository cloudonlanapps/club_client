import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/evaluation_view_sizes.dart';
import '../constants/evaluation_view_strings.dart';

/// A muted line standing in for content — an empty list, a missing or
/// failed item — with an optional Back action.
class EvaluationMessage extends StatelessWidget {
  /// Shows [message].
  const EvaluationMessage({required this.message, this.onBack, super.key});

  /// What to say.
  final String message;

  /// Leaves the view, when given.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final back = onBack;
    return Padding(
      padding: const EdgeInsets.all(EvaluationViewSizes.pagePadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: EvaluationViewSizes.smallGap,
        children: [
          Text(message, style: ShadTheme.of(context).textTheme.muted),
          if (back != null)
            ShadButton.ghost(
              onPressed: back,
              child: const Text(EvaluationViewStrings.back),
            ),
        ],
      ),
    );
  }
}
