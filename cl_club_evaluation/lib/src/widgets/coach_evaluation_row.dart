import 'package:cl_remote_store/cl_remote_store.dart'
    show clEvaluationTemplatesMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show EvaluationStaffView;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_lib/ui_lib.dart' show EntityCard, EntityImage;

import '../constants/evaluation_view_strings.dart';
import '../models/evaluation_period_dates.dart';
import '../utils/evaluation_initial.dart';
import '../utils/evaluation_names.dart';

/// One of the coach's evaluations: the member it is about, its template,
/// and the event or "General" with its review period.
class CoachEvaluationRow extends ConsumerWidget {
  /// A row for [evaluation].
  const CoachEvaluationRow({
    required this.evaluation,
    required this.onTap,
    super.key,
  });

  /// The evaluation.
  final EvaluationStaffView evaluation;

  /// Opens it.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = evaluation;
    final member = EvaluationNames.person(ref, e.createdFor);
    final templates = ref.watch(clEvaluationTemplatesMasterProvider);
    final template = templates.valueOrNull?[e.templateId]?.name;
    final period = EvaluationPeriodDates.range(
      e.periodStartUtc,
      e.periodEndUtc,
    );
    return EntityCard(
      image: EntityImage.initials(evaluationInitial(member)),
      title: member,
      caption: [
        ?template,
        EvaluationNames.event(ref, member: e.createdFor, eventId: e.eventId),
        ?period,
      ].join(EvaluationViewStrings.separator),
      onTap: onTap,
    );
  }
}
