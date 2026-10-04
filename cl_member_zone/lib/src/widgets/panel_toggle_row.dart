import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/panel_descriptor.dart';

/// A single row inside the manage-panels dialog: a checkbox bound to a
/// panel descriptor.
class PanelToggleRow extends StatelessWidget {
  const PanelToggleRow({
    required this.descriptor,
    required this.checked,
    required this.onChanged,
    super.key,
  });

  final PanelDescriptor descriptor;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!checked),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Row(
          children: [
            ShadCheckbox(
              value: checked,
              onChanged: onChanged,
            ),
            const SizedBox(width: 12),
            Icon(
              descriptor.icon,
              size: 16,
              color: theme.colorScheme.mutedForeground,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                descriptor.title,
                style: theme.textTheme.p,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
