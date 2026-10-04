import 'package:flutter/widgets.dart';

import '../constants/evaluation_view_sizes.dart';

/// A view's scrolling page: [children] in a padded column, no wider than
/// [EvaluationViewSizes.maxContentWidth].
class EvaluationPage extends StatelessWidget {
  /// Lays out [children].
  const EvaluationPage({required this.children, super.key});

  /// The page's content, top to bottom.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(EvaluationViewSizes.pagePadding),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: EvaluationViewSizes.maxContentWidth,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: EvaluationViewSizes.sectionGap,
          children: children,
        ),
      ),
    ),
  );
}
