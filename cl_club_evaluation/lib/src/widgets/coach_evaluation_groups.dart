import 'package:club_sdk_2/club_sdk_2.dart' show EvaluationStaffView;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/evaluation_view_sizes.dart';
import '../constants/evaluation_view_strings.dart';
import '../models/evaluation_status_labels.dart';
import 'coach_evaluation_row.dart';

/// The coach's live evaluations in groups by status, in
/// [EvaluationStatusLabels.groupOrder] — Drafts, Finalized (awaiting
/// publication), Published — each most recently updated first;
/// empty groups are left out, and soft-deleted evaluations too.
class CoachEvaluationGroups extends StatelessWidget {
  /// Groups [evaluations].
  const CoachEvaluationGroups({
    required this.evaluations,
    required this.onOpen,
    super.key,
  });

  /// The coach's evaluations, deleted ones included.
  final Iterable<EvaluationStaffView> evaluations;

  /// Opens the evaluation with this id.
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final live = evaluations.where((e) => e.deletedAtUtc == null).toList()
      ..sort((a, b) => b.updatedAtUtc.compareTo(a.updatedAtUtc));
    if (live.isEmpty) {
      return Text(
        EvaluationViewStrings.noEvaluations,
        style: theme.textTheme.muted,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: EvaluationViewSizes.rowGap,
      children: [
        for (final status in EvaluationStatusLabels.groupOrder)
          if (live.any((e) => e.status == status)) ...[
            Text(
              EvaluationStatusLabels.group(status),
              style: theme.textTheme.large,
            ),
            for (final e in live)
              if (e.status == status)
                CoachEvaluationRow(evaluation: e, onTap: () => onOpen(e.id)),
          ],
      ],
    );
  }
}
