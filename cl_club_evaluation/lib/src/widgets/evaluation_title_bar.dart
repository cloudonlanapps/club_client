import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/evaluation_view_sizes.dart';

/// A view's title with its [actions] at the end; on a narrow page the
/// actions wrap under the title.
class EvaluationTitleBar extends StatelessWidget {
  /// Titles a view [title], with [actions].
  const EvaluationTitleBar({
    required this.title,
    required this.actions,
    super.key,
  });

  /// The view's title.
  final String title;

  /// Buttons, in reading order; the last is the primary one.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: EvaluationViewSizes.smallGap,
    runSpacing: EvaluationViewSizes.smallGap,
    children: [
      Text(title, style: ShadTheme.of(context).textTheme.h4),
      Wrap(
        spacing: EvaluationViewSizes.smallGap,
        runSpacing: EvaluationViewSizes.smallGap,
        children: actions,
      ),
    ],
  );
}
