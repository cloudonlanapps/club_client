import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// One labelled detail row of a profile section card, or `null` when [value]
/// is empty (so the section card can drop it).
Widget? profileDetailRow(
  BuildContext context,
  IconData icon,
  String label,
  String? value,
) {
  if (value == null || value.isEmpty) return null;
  final theme = ShadTheme.of(context);
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.mutedForeground),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.small),
              const SizedBox(height: 2),
              Text(value, style: theme.textTheme.p),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Read-only rows for a section card, dropping the empty ones.
Widget profileSectionRows(List<Widget?> rows) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: rows.whereType<Widget>().toList(),
  );
}
