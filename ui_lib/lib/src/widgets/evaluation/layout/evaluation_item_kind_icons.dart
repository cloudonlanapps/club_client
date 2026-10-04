import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../models/evaluation_item_kind.dart';

/// The icon of each choice in the add menu.
abstract final class EvaluationItemKindIcons {
  /// A section.
  static const IconData section = LucideIcons.folder;

  /// An existing question, copied.
  static const IconData existing = LucideIcons.copy;

  /// The icon of [kind].
  static IconData of(EvaluationItemKind kind) => switch (kind) {
    EvaluationItemKind.rating => LucideIcons.star,
    EvaluationItemKind.yesNo => LucideIcons.toggleLeft,
    EvaluationItemKind.singleChoice => LucideIcons.circleDot,
    EvaluationItemKind.multipleChoice => LucideIcons.squareCheck,
    EvaluationItemKind.number => LucideIcons.hash,
    EvaluationItemKind.qa => LucideIcons.messageSquareText,
    EvaluationItemKind.info => LucideIcons.info,
  };
}
