import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ThemedMarkdown;

/// One membership benefit.
///
/// The old model gave each benefit a title and a description; the server
/// carries a plain list of lines, so a benefit is one line now.
class PublicEventBenefitCard extends StatelessWidget {
  const PublicEventBenefitCard({
    required this.title,
    required this.color,
    super.key,
  });
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(LucideIcons.check, size: 28, color: color),
            ),
            const SizedBox(height: 16),
            ThemedMarkdown(
              data: title,
              selectable: false,
              textStyle: theme.textTheme.p.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
