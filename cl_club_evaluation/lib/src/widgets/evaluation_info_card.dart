import 'package:club_sdk_2/club_sdk_2.dart' show EvaluationStaffView;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_lib/ui_lib.dart' show ReadOnlyField;

import '../constants/evaluation_view_sizes.dart';
import '../constants/evaluation_view_strings.dart';
import '../models/evaluation_period_dates.dart';
import '../models/evaluation_status_labels.dart';
import '../utils/evaluation_names.dart';
import 'evaluation_titled_card.dart';

/// **Review Info**: read-only facts about [evaluation], formatted as the
/// profile's Account Info card — who created it, its owner when it was
/// transferred, when it was created, updated and published, its status
/// and its template.
class EvaluationInfoCard extends ConsumerWidget {
  /// The facts of [evaluation], written against [templateName].
  const EvaluationInfoCard({
    required this.evaluation,
    required this.templateName,
    super.key,
  });

  /// The evaluation, as its owner reads it.
  final EvaluationStaffView evaluation;

  /// Its template's name.
  final String templateName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = evaluation;
    final owner = e.owner;
    final published = e.publishedAtUtc;
    return EvaluationTitledCard(
      title: EvaluationViewStrings.reviewInfo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: EvaluationViewSizes.cardItemGap,
        children: [
          ReadOnlyField(
            label: EvaluationViewStrings.createdBy,
            value: EvaluationNames.person(ref, e.createdBy),
          ),
          if (owner != null && owner != e.createdBy)
            ReadOnlyField(
              label: EvaluationViewStrings.owner,
              value: EvaluationNames.person(ref, owner),
            ),
          ReadOnlyField(
            label: EvaluationViewStrings.created,
            value: EvaluationPeriodDates.moment(e.createdAtUtc),
          ),
          ReadOnlyField(
            label: EvaluationViewStrings.updated,
            value: EvaluationPeriodDates.moment(e.updatedAtUtc),
          ),
          if (published != null)
            ReadOnlyField(
              label: EvaluationViewStrings.publishedAt,
              value: EvaluationPeriodDates.moment(published),
            ),
          ReadOnlyField(
            label: EvaluationViewStrings.status,
            value: EvaluationStatusLabels.of(e.status),
          ),
          ReadOnlyField(
            label: EvaluationViewStrings.template,
            value: templateName,
          ),
        ],
      ),
    );
  }
}
