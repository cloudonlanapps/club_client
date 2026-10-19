import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/page_cta_data.dart';
import '../../theme/text_theme_extensions.dart';
import '../markdown/themed_markdown.dart';

/// CTA section with title, description (supports markdown), and action buttons.
///
/// Primary button is always shown. Secondary button only appears when both
/// [PageCtaData.secondaryButtonText] and [PageCtaData.secondaryRoute] are set.
/// The labels and routes come from [PageCtaData]; [onNavigate] is handed a
/// button's route, so the host decides what following it means.
class CtaSection extends StatelessWidget {
  const CtaSection({
    required this.data,
    required this.isMobile,
    super.key,
    this.onNavigate,
  });
  final PageCtaData data;
  final bool isMobile;

  /// Called with the route of the button pressed.
  final ValueChanged<String>? onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final showSecondary =
        data.secondaryButtonText != null && data.secondaryRoute != null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 60,
        horizontal: isMobile ? 24 : 48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Text(
                data.title,
                style: theme.textTheme.subsectionTitle(isMobile: isMobile),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ThemedMarkdown(
                data: data.description,
                selectable: false,
                textStyle: theme.textTheme.muted,
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  ShadButton(
                    onPressed: () => onNavigate?.call(data.primaryRoute),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.userPlus, size: 16),
                        const SizedBox(width: 8),
                        Text(data.primaryButtonText),
                      ],
                    ),
                  ),
                  if (showSecondary)
                    ShadButton.outline(
                      onPressed: () => onNavigate?.call(data.secondaryRoute!),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.mail, size: 16),
                          const SizedBox(width: 8),
                          Text(data.secondaryButtonText!),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
