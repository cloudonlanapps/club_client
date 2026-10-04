import 'package:club_sdk_2/club_sdk_2.dart' show EvaluationStatus;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/evaluation_view_sizes.dart';
import 'evaluation_status_stamp.dart';

/// The head of the owner's evaluation: the member's name as [title], the
/// review's title as [subtitle], and the stamp [status] earns on the right.
/// No event and no status text: the stamp and the actions say it.
class EvaluationHeadCard extends StatelessWidget {
  /// The head of an evaluation in [status].
  const EvaluationHeadCard({
    required this.title,
    required this.subtitle,
    required this.status,
    super.key,
  });

  /// The member's name.
  final String title;

  /// The review's (template's) title.
  final String subtitle;

  /// The evaluation's status.
  final EvaluationStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadCard(
      padding: const EdgeInsets.all(EvaluationViewSizes.cardPadding),
      child: Row(
        spacing: EvaluationViewSizes.smallGap,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.h4),
                Text(subtitle, style: theme.textTheme.muted),
              ],
            ),
          ),
          EvaluationStatusStamp(status: status),
        ],
      ),
    );
  }
}
