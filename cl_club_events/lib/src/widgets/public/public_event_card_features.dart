import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// A programme card's "What's Included" list.
///
/// A vertical list rather than a `Wrap`, so a long feature wraps inside its
/// own row instead of pushing the row past the card.
class PublicEventCardFeatures extends StatelessWidget {
  const PublicEventCardFeatures({
    required this.title,
    required this.features,
    super.key,
  });

  final String title;
  final List<String> features;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            for (final feature in features)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Icon(
                      LucideIcons.check,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: theme.textTheme.small.copyWith(height: 1.45),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
