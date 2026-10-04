import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Wrap of toggle buttons for picking a [UserStatus].
///
/// Iterates `UserStatus.values` so adding a new status to the SDK does not
/// require touching this widget.
class UserStatusSelector extends StatelessWidget {
  const UserStatusSelector({
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final UserStatus value;
  final void Function(UserStatus status) onChanged;
  final bool enabled;

  String _label(UserStatus s) {
    final n = s.name;
    return n[0].toUpperCase() + n.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status', style: theme.textTheme.small),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in UserStatus.values)
              if (value == s)
                ShadButton.secondary(
                  size: ShadButtonSize.sm,
                  onPressed: enabled ? () => onChanged(s) : null,
                  child: Text(_label(s)),
                )
              else
                ShadButton.outline(
                  size: ShadButtonSize.sm,
                  onPressed: enabled ? () => onChanged(s) : null,
                  child: Text(_label(s)),
                ),
          ],
        ),
      ],
    );
  }
}
