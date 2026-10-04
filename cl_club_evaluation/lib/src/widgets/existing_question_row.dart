import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/evaluation_view_sizes.dart';
import '../constants/evaluation_view_strings.dart';
import '../models/evaluation_item_adapter.dart';

/// One question found by the existing-question search: its question, and
/// the template and type it comes from. Tapping picks it.
class ExistingQuestionRow extends StatelessWidget {
  /// A row for [hit].
  const ExistingQuestionRow({
    required this.hit,
    required this.onTap,
    super.key,
  });

  /// The question found.
  final sdk.EvaluationTemplateItemHit hit;

  /// Picks it.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final item = hit.item;
    final question = item is sdk.EvaluationQuestionItem ? item.question : '';
    final kind = EvaluationItemAdapter.kindOf(item.type).label;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: EvaluationViewSizes.smallGap,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(question, style: theme.textTheme.p),
              Text(
                '${hit.templateName}${EvaluationViewStrings.separator}$kind',
                style: theme.textTheme.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
