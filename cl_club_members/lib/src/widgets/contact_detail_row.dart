import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show DetailRow;

/// One labelled row of the profile's Contact card whose value is a widget:
/// a muted [icon], then [label] over [child]. Laid out as the card's text
/// rows are.
class ContactDetailRow extends StatelessWidget {
  /// A row showing [child] under [label].
  const ContactDetailRow({
    required this.icon,
    required this.label,
    required this.child,
    super.key,
  });

  /// The row's icon.
  final IconData icon;

  /// What the value is.
  final String label;

  /// The value.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: DetailRow.rowGap),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: DetailRow.iconGap,
        children: [
          Icon(
            icon,
            size: DetailRow.iconSize,
            color: theme.colorScheme.mutedForeground,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: DetailRow.labelGap,
              children: [
                Text(label, style: theme.textTheme.small),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
