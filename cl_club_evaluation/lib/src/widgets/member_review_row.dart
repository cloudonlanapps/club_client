import 'package:club_sdk_2/club_sdk_2.dart' show EvaluationMemberView;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show EntityCard, EntityImage;

import '../constants/evaluation_view_strings.dart';
import '../models/evaluation_period_dates.dart';
import '../utils/evaluation_initial.dart';
import '../utils/evaluation_names.dart';

/// One published review in the member's list: its template's name, the
/// event or "General" and when it was published, and the coach.
class MemberReviewRow extends ConsumerWidget {
  /// A row for [review].
  const MemberReviewRow({required this.review, required this.onTap, super.key});

  /// The review.
  final EvaluationMemberView review;

  /// Opens it.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final published = review.publishedAtUtc;
    final event = EvaluationNames.event(
      ref,
      member: review.createdFor,
      eventId: review.eventId,
    );
    final coach = EvaluationNames.person(ref, review.effectiveOwner);
    return EntityCard(
      image: EntityImage.initials(evaluationInitial(review.template.name)),
      title: review.template.name,
      caption: [
        event,
        if (published != null)
          EvaluationViewStrings.publishedOn(
            EvaluationPeriodDates.localDay(published),
          ),
      ].join(EvaluationViewStrings.separator),
      body: Text(
        EvaluationViewStrings.byCoach(coach),
        style: ShadTheme.of(context).textTheme.muted,
      ),
      onTap: onTap,
    );
  }
}
