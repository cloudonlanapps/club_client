import 'package:flutter/widgets.dart';

import '../../constants/form_spacing.dart';

/// Two rows of a user form that sit side by side where there is room and
/// stack where there is not.
class UserFieldPair extends StatelessWidget {
  const UserFieldPair({
    required this.first,
    required this.second,
    this.minWidth = sideBySideMinWidth,
    super.key,
  });

  /// Width from which a pair sits side by side by default.
  static const double sideBySideMinWidth = 500;

  /// A [minWidth] that keeps the pair side by side at every width.
  static const double always = 0;

  /// A [minWidth] that keeps the pair stacked at every width.
  static const double never = double.infinity;

  /// Between the two rows when they sit side by side.
  static const double gap = 12;

  /// The left row, or the upper one when stacked.
  final Widget first;

  /// The right row, or the lower one when stacked.
  final Widget second;

  /// The available width from which the rows sit side by side.
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < minWidth) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: FormSpacing.rowGap,
            children: [first, second],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: gap,
          children: [
            Expanded(child: first),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}
