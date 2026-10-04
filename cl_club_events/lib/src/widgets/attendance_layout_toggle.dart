import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Right-aligned "Group by status" switch above the register.
class AttendanceLayoutToggle extends StatelessWidget {
  const AttendanceLayoutToggle({
    required this.groupByStatus,
    required this.onChanged,
    super.key,
  });

  final bool groupByStatus;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Group by status',
            style: theme.textTheme.muted.copyWith(fontSize: 12),
          ),
          const SizedBox(width: 8),
          ShadSwitch(value: groupByStatus, onChanged: onChanged),
        ],
      ),
    );
  }
}
