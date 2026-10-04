import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// An amber notice above the register explaining why rows are read-only:
/// the attendance window is not open yet, or the edit window has closed.
class AttendanceWindowBanner extends StatelessWidget {
  const AttendanceWindowBanner({
    required this.icon,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.muted.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
