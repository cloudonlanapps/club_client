import 'package:flutter/widgets.dart';

import '../constants/evaluation_view_sizes.dart';
import '../constants/evaluation_view_strings.dart';
import 'evaluation_period_rows.dart';
import 'evaluation_titled_card.dart';

/// The Review Period section read-only — the member's view — formatted as
/// the owner's editable one without its pencil; left out when there is no
/// event and no period.
class EvaluationPeriodSection extends StatelessWidget {
  /// The section of a review of [member].
  const EvaluationPeriodSection({
    required this.member,
    required this.eventId,
    required this.startUtc,
    required this.endUtc,
    super.key,
  });

  /// The member the review is about.
  final String member;

  /// Its event, or `null` for a general review.
  final int? eventId;

  /// The first day of its period.
  final DateTime? startUtc;

  /// The last day of its period.
  final DateTime? endUtc;

  @override
  Widget build(BuildContext context) {
    if (EvaluationPeriodRows.isEmptyFor(
      eventId: eventId,
      startUtc: startUtc,
      endUtc: endUtc,
    )) {
      return const SizedBox.shrink();
    }
    return EvaluationTitledCard(
      title: EvaluationViewStrings.reviewPeriod,
      titleGap: EvaluationViewSizes.sectionTitleGap,
      child: EvaluationPeriodRows(
        member: member,
        eventId: eventId,
        startUtc: startUtc,
        endUtc: endUtc,
      ),
    );
  }
}
