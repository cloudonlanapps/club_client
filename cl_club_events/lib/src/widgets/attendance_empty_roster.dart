import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The register when nobody is enrolled.
class AttendanceEmptyRoster extends StatelessWidget {
  const AttendanceEmptyRoster({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.checklist,
            size: 48,
            color: theme.colorScheme.mutedForeground,
          ),
          const SizedBox(height: 8),
          Text('No enrolled members', style: theme.textTheme.muted),
        ],
      ),
    );
  }
}
