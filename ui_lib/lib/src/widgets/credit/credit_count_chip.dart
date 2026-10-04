import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// A member's credit as an icon and a number, or an "add credit" mark
/// (club_core#102, #105).
///
/// Pure UI: the connected `CreditChip` in `cl_club_credits` decides whether
/// it shows, which number it carries and what a tap opens. Monochrome and
/// outlined, per the UI style rules. [credits] null shows the icon alone
/// (the number is loading).
class CreditCountChip extends StatelessWidget {
  const CreditCountChip({
    this.credits,
    this.onTap,
    this.add = false,
    super.key,
  });

  /// The number shown beside the coin; null while unknown.
  final int? credits;

  /// Opens the member's credit view. Null renders the chip inert.
  final VoidCallback? onTap;

  /// Shows a plus in place of the number: the tap is for adding credit.
  final bool add;

  /// Semantic label, also what tests find the chip by.
  String get semanticLabel => add
      ? 'Add credit'
      : credits == null
      ? 'Credit'
      : 'Credit $credits';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: semanticLabel,
      button: onTap != null,
      excludeSemantics: true,
      child: ShadButton.outline(
        size: ShadButtonSize.sm,
        onPressed: onTap,
        leading: const Icon(LucideIcons.coins, size: 14),
        child: add
            ? const Icon(LucideIcons.plus, size: 14)
            : Text(credits?.toString() ?? ''),
      ),
    );
  }
}
