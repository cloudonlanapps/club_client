import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/evaluation_spacing.dart';
import '../../../constants/evaluation_strings.dart';
import '../common/evaluation_icon_action.dart';

/// One row of the layout outline: a muted [caption] over the [title], in a
/// bordered box, indented when inside a section. Tapping it calls [onTap];
/// while sorting the arrows move it.
class EvaluationOutlineRow extends StatelessWidget {
  /// A row reading [caption] and [title].
  const EvaluationOutlineRow({
    required this.caption,
    required this.title,
    this.indented = false,
    this.emphasised = false,
    this.showArrows = false,
    this.onTap,
    this.onMoveUp,
    this.onMoveDown,
    this.trailing,
    super.key,
  });

  /// The kind, or "Section".
  final String caption;

  /// The item's first line, or the section's title.
  final String title;

  /// Whether the row is an item inside a section.
  final bool indented;

  /// Whether the title stands out (a section header).
  final bool emphasised;

  /// Whether the reorder arrows show.
  final bool showArrows;

  /// Edits the row; `null` makes it inert.
  final VoidCallback? onTap;

  /// Moves the row up; `null` when it cannot.
  final VoidCallback? onMoveUp;

  /// Moves the row down; `null` when it cannot.
  final VoidCallback? onMoveDown;

  /// Shown before the actions, e.g. a section's own "+".
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final text = theme.textTheme;
    final tap = onTap;
    final body = DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.border),
        borderRadius: theme.radius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(EvaluationSpacing.rowPadding),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(caption, style: text.muted),
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: emphasised ? text.large : text.p,
                  ),
                ],
              ),
            ),
            ?trailing,
            if (showArrows) ...[
              EvaluationIconAction(
                label: EvaluationStrings.moveUp,
                icon: LucideIcons.arrowUp,
                onPressed: onMoveUp,
              ),
              EvaluationIconAction(
                label: EvaluationStrings.moveDown,
                icon: LucideIcons.arrowDown,
                onPressed: onMoveDown,
              ),
            ],
          ],
        ),
      ),
    );
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: indented ? EvaluationSpacing.indent : 0,
      ),
      child: tap == null
          ? body
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: tap,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: body,
              ),
            ),
    );
  }
}
