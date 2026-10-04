import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ThemedMarkdown;

/// Individual value card with icon, title, and description.
class ValueCard extends StatelessWidget {
  const ValueCard({
    required this.icon,
    required this.title,
    required this.description,
    super.key,
  });
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = screenWidth < 768 ? screenWidth - 48 : 320.0;

    return ShadCard(
      width: cardWidth,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text(title, style: theme.textTheme.h3, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ThemedMarkdown(
              data: description,
              selectable: false,
              textStyle: theme.textTheme.muted,
            ),
          ],
        ),
      ),
    );
  }
}
