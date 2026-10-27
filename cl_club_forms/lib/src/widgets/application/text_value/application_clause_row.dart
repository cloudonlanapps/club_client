import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// One text of the library, tapped to paste it: its name, if any, above
/// its text.
class ApplicationClauseRow extends StatelessWidget {
  const ApplicationClauseRow({
    required this.text,
    required this.enabled,
    required this.onTap,
    this.name,
    super.key,
  });

  /// The text as the row shows it.
  final String text;

  /// The text's name; null for none.
  final String? name;

  /// Whether the row responds.
  final bool enabled;

  /// Pastes the text.
  final VoidCallback onTap;

  /// The padding inside the row.
  static const EdgeInsets padding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  );

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final name = this.name;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.border),
            borderRadius: theme.radius,
          ),
          child: Padding(
            padding: padding,
            child: Opacity(
              opacity: enabled ? 1 : 0.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (name != null) Text(name, style: theme.textTheme.muted),
                  Text(text, style: theme.textTheme.small),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
