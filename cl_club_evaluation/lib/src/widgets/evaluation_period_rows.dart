import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show DetailRow;

import '../constants/evaluation_view_strings.dart';
import '../models/evaluation_period_dates.dart';
import '../utils/evaluation_names.dart';

/// The Review Period section's statements, in the profile's detail-row
/// style: **Event** with its title, only when the review is about an event
/// (never "General"), and **Review Period** "from to", only when set.
class EvaluationPeriodRows extends ConsumerWidget {
  /// The statements of a review of [member].
  const EvaluationPeriodRows({
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

  /// Whether there is nothing to state: no event and no period.
  static bool isEmptyFor({
    required int? eventId,
    required DateTime? startUtc,
    required DateTime? endUtc,
  }) =>
      eventId == null &&
      EvaluationPeriodDates.statement(startUtc, endUtc) == null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = eventId;
    final period = EvaluationPeriodDates.statement(startUtc, endUtc);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (event != null)
          DetailRow(
            icon: LucideIcons.calendarDays,
            label: EvaluationViewStrings.event,
            value: EvaluationNames.event(ref, member: member, eventId: event),
          ),
        if (period != null)
          DetailRow(
            icon: LucideIcons.calendarRange,
            label: EvaluationViewStrings.reviewPeriod,
            value: period,
          ),
      ],
    );
  }
}
