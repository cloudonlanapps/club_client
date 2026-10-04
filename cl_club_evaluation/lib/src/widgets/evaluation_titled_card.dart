import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/evaluation_view_sizes.dart';

/// A section card in the member profile's formatting: a `ShadCard` padded
/// [EvaluationViewSizes.cardPadding], its [title] in `h4`, then [child]
/// after [titleGap] — the profile's management and info cards use
/// [EvaluationViewSizes.cardTitleGap]; a read-only section matching an
/// `EditableSectionCard` uses [EvaluationViewSizes.sectionTitleGap].
class EvaluationTitledCard extends StatelessWidget {
  /// A card titled [title] holding [child].
  const EvaluationTitledCard({
    required this.title,
    required this.child,
    this.titleGap = EvaluationViewSizes.cardTitleGap,
    super.key,
  });

  /// The card's title.
  final String title;

  /// The card's content.
  final Widget child;

  /// The gap under the title.
  final double titleGap;

  @override
  Widget build(BuildContext context) => ShadCard(
    padding: const EdgeInsets.all(EvaluationViewSizes.cardPadding),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: titleGap,
      children: [
        Text(title, style: ShadTheme.of(context).textTheme.h4),
        child,
      ],
    ),
  );
}
