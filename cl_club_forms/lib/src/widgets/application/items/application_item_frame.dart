import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/form_spacing.dart';

/// The bordered box around one item of an application list: its [title]
/// and [actions] on top, what it holds below.
class ApplicationItemFrame extends StatelessWidget {
  const ApplicationItemFrame({
    required this.title,
    required this.actions,
    required this.child,
    super.key,
  });

  /// The item's padding inside its border.
  static const double padding = 12;

  /// The rounding of the item's border.
  static const double radius = 8;

  /// The size of the item's action icons.
  static const double iconSize = 16;

  /// The item's place in its list (`Term 2`).
  final String title;

  /// The item's buttons.
  final Widget actions;

  /// What the item holds.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.border),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FormSpacing.labelGap,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: theme.textTheme.muted)),
                actions,
              ],
            ),
            child,
          ],
        ),
      ),
    );
  }
}
