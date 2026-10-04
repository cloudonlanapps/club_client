import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// One labelled detail of a section card: a muted [icon], then [label]
/// over [value] — the row style of the profile's Personal details card.
class DetailRow extends StatelessWidget {
  /// A row showing [value] under [label].
  const DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  /// The row's icon.
  final IconData icon;

  /// What the value is.
  final String label;

  /// The value.
  final String value;

  /// Gap under a row.
  static const double rowGap = 12;

  /// Size of the icon.
  static const double iconSize = 16;

  /// Gap between the icon and the text.
  static const double iconGap = 10;

  /// Gap between the label and the value.
  static const double labelGap = 2;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: rowGap),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: iconGap,
        children: [
          Icon(icon, size: iconSize, color: theme.colorScheme.mutedForeground),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: labelGap,
              children: [
                Text(label, style: theme.textTheme.small),
                Text(value, style: theme.textTheme.p),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
