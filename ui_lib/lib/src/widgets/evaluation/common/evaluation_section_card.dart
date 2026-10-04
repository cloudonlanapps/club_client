import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/evaluation_spacing.dart';
import '../../../models/evaluation_item_value.dart';

/// A card of [items], separated by thin dividers, under [title] when there
/// is one (a section) and untitled otherwise (the closing run);
/// [itemBuilder] renders one item.
class EvaluationSectionCard extends StatelessWidget {
  /// A card of [items], titled [title] when it is not `null`.
  const EvaluationSectionCard({
    required this.items,
    required this.itemBuilder,
    this.title,
    super.key,
  });

  /// The section's title; `null` for an untitled card.
  final String? title;

  /// Its items, in order.
  final List<EvaluationItemValue> items;

  /// Renders one item.
  final Widget Function(EvaluationItemValue item) itemBuilder;

  @override
  Widget build(BuildContext context) => ShadCard(
    title: title == null ? null : Text(title!),
    child: Padding(
      padding: EdgeInsets.only(
        top: title == null ? 0 : EvaluationSpacing.elementGap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: EvaluationSpacing.elementGap,
        children: [
          for (final (i, item) in items.indexed) ...[
            if (i > 0) const ShadSeparator.horizontal(),
            itemBuilder(item),
          ],
        ],
      ),
    ),
  );
}
