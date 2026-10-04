import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/evaluation_strings.dart';
import '../../../models/evaluation_item_kind.dart';
import 'evaluation_add_menu_entry.dart';
import 'evaluation_item_kind_icons.dart';

/// A "+" that drops down what can be added: a question of each kind, an
/// info text, and — when given — a section and an existing question. Full
/// width at the end of the outline; [compact] as an icon in a section's
/// header.
class EvaluationAddBar extends StatefulWidget {
  /// Adds through the given callbacks.
  const EvaluationAddBar({
    required this.onAddItem,
    this.onAddSection,
    this.onAddExisting,
    this.compact = false,
    super.key,
  });

  /// Adds an item of a kind.
  final ValueChanged<EvaluationItemKind> onAddItem;

  /// Adds a section; `null` hides the option.
  final VoidCallback? onAddSection;

  /// Copies an existing question; `null` hides the option.
  final VoidCallback? onAddExisting;

  /// An icon button instead of a full-width bar.
  final bool compact;

  @override
  State<EvaluationAddBar> createState() => EvaluationAddBarState();
}

/// State of [EvaluationAddBar]: whether the menu is open.
class EvaluationAddBarState extends State<EvaluationAddBar> {
  /// Opens and closes the menu.
  final ShadPopoverController menu = ShadPopoverController();

  @override
  void dispose() {
    menu.dispose();
    super.dispose();
  }

  /// Closes the menu, then runs [action].
  void choose(VoidCallback action) {
    menu.hide();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final section = widget.onAddSection;
    final existing = widget.onAddExisting;
    return ShadPopover(
      controller: menu,
      popover: (context) => IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final kind in EvaluationItemKind.values)
              EvaluationAddMenuEntry(
                icon: EvaluationItemKindIcons.of(kind),
                label: kind.label,
                onPressed: () => choose(() => widget.onAddItem(kind)),
              ),
            if (existing != null)
              EvaluationAddMenuEntry(
                icon: EvaluationItemKindIcons.existing,
                label: EvaluationStrings.existingQuestion,
                onPressed: () => choose(existing),
              ),
            if (section != null)
              EvaluationAddMenuEntry(
                icon: EvaluationItemKindIcons.section,
                label: EvaluationStrings.section,
                onPressed: () => choose(section),
              ),
          ],
        ),
      ),
      child: Semantics(
        label: widget.compact
            ? EvaluationStrings.addToSection
            : EvaluationStrings.addItem,
        button: true,
        child: widget.compact
            ? ShadIconButton.ghost(
                icon: const Icon(LucideIcons.plus),
                onPressed: menu.toggle,
              )
            : ShadButton.outline(
                width: double.infinity,
                onPressed: menu.toggle,
                child: const Icon(LucideIcons.plus),
              ),
      ),
    );
  }
}
