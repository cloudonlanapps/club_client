import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Shown when the user has deselected every panel — prompts them to use the
/// manage button to add panels back.
class EmptyDashboard extends StatelessWidget {
  const EmptyDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No panels selected. Tap + to add panels.',
          style: theme.textTheme.muted,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
