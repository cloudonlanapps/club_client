import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// A muted note under an event's schedule, with a lock icon: why part of
/// the schedule can no longer be changed, and what still can.
class ScheduleNote extends StatelessWidget {
  const ScheduleNote({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final muted = theme.colorScheme.mutedForeground;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(LucideIcons.lock, size: 13, color: muted),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.small.copyWith(color: muted),
          ),
        ),
      ],
    );
  }
}
