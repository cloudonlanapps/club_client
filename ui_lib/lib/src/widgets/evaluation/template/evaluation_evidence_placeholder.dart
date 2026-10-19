import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/evaluation_spacing.dart';
import '../../../constants/evaluation_strings.dart';

/// Where an item that allows evidence takes it, in a template's preview
/// (club_client#28): a muted, bordered line that does nothing, since a
/// preview has nowhere to upload to.
class EvaluationEvidencePlaceholder extends StatelessWidget {
  /// The placeholder.
  const EvaluationEvidencePlaceholder({super.key});

  /// Size of the icon.
  static const double iconSize = 16;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final muted = theme.colorScheme.mutedForeground;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.border),
        borderRadius: theme.radius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(EvaluationSpacing.rowPadding),
        child: Row(
          spacing: EvaluationSpacing.smallGap,
          children: [
            Icon(LucideIcons.paperclip, size: iconSize, color: muted),
            Flexible(
              child: Text(
                EvaluationStrings.previewEvidence,
                style: theme.textTheme.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
