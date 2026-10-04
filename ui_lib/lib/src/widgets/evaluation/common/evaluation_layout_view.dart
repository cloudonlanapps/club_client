import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/evaluation_spacing.dart';
import '../../../models/evaluation_item_value.dart';
import '../../../models/evaluation_layout_entry.dart';
import '../../../utils/evaluation_closing_run.dart';
import 'evaluation_section_card.dart';

/// A layout as cards, in the template's order: each item outside a section
/// in its own card, each section as a titled card of its items separated
/// by thin dividers, and the closing run ([EvaluationClosingRun]) last,
/// outside any section: one untitled card of its items separated by thin
/// dividers. [itemBuilder] renders one item.
class EvaluationLayoutView extends StatelessWidget {
  /// Shows [layout].
  const EvaluationLayoutView({
    required this.layout,
    required this.itemBuilder,
    super.key,
  });

  /// The items and sections, in order.
  final List<EvaluationLayoutEntry> layout;

  /// Renders one item.
  final Widget Function(EvaluationItemValue item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final closing = EvaluationClosingRun.start(layout);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: EvaluationSpacing.elementGap,
      children: [
        for (final entry in layout.take(closing))
          if (entry.item case final item?)
            ShadCard(child: itemBuilder(item))
          else
            EvaluationSectionCard(
              title: entry.sectionTitle,
              items: entry.sectionItems,
              itemBuilder: itemBuilder,
            ),
        if (closing < layout.length)
          EvaluationSectionCard(
            items: [for (final e in layout.skip(closing)) e.item!],
            itemBuilder: itemBuilder,
          ),
      ],
    );
  }
}
