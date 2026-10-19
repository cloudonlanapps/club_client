import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/page_empty_state_data.dart';
import '../markdown/themed_markdown.dart';

/// Empty state section with card, icon, title, description, and button.
class EmptyStateSection extends StatelessWidget {
  const EmptyStateSection({
    required this.data,
    required this.isMobile,
    super.key,
    this.onAction,
  });
  final PageEmptyStateData data;
  final bool isMobile;

  /// Called when the empty state's button is pressed (the website opens its
  /// contact page).
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 60,
        horizontal: isMobile ? 24 : 48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ShadCard(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.sparkles,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    data.title,
                    style: theme.textTheme.h2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ThemedMarkdown(
                    data: data.description,
                    selectable: false,
                    textStyle: theme.textTheme.muted.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  ShadButton(
                    onPressed: onAction,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.bell, size: 16),
                        const SizedBox(width: 8),
                        Text(data.buttonText),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
