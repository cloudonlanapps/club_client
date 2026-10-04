import 'package:cl_remote_store/cl_remote_store.dart'
    show
        clEvaluationTemplatesMasterProvider,
        clEvaluationsMasterProvider,
        evaluationsProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/evaluation_view_strings.dart';
import '../widgets/coach_evaluation_groups.dart';
import '../widgets/evaluation_heading.dart';
import '../widgets/evaluation_message.dart';
import '../widgets/evaluation_page.dart';
import '../widgets/start_review_dialog.dart';
import '../widgets/template_start_list.dart';

/// The coach's view of reviews (design 4.2, `reviews`): their own
/// evaluations grouped by status — Drafts, Finalized (awaiting
/// publication), Published; soft-deleted ones left out — and then, under
/// **New**, the templates, each with **Start**, which opens the start
/// dialog with the template fixed and then [onOpenEvaluation] with the new
/// draft. **Manage Templates**, at the bottom right, opens the template
/// library ([onOpenTemplates]) for every coach.
///
/// Renders nothing unless the server runs evaluations.
class CoachReviewsView extends ConsumerWidget {
  /// The reviews of [currentUser], a coach.
  const CoachReviewsView({
    required this.currentUser,
    required this.onOpenEvaluation,
    required this.onOpenTemplates,
    super.key,
  });

  /// The signed-in coach.
  final UserPrivate currentUser;

  /// Opens the evaluation with this id.
  final ValueChanged<int> onOpenEvaluation;

  /// Opens the template library, where templates are created, edited,
  /// duplicated and deleted.
  final VoidCallback onOpenTemplates;

  /// Starts a review from template [templateId], opening it when created.
  Future<void> start(BuildContext context, int templateId) async {
    final id = await showStartReviewDialog(
      context: context,
      currentUser: currentUser,
      templateId: templateId,
    );
    if (id != null) onOpenEvaluation(id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    assert(
      currentUser.roles.isCoach,
      'CoachReviewsView called for ${currentUser.username}, who is not a '
      'coach. Screen gate failed.',
    );
    if (ref.watch(evaluationsProvider) != true) return const SizedBox.shrink();
    final evaluations = ref.watch(clEvaluationsMasterProvider);
    final templates = ref.watch(clEvaluationTemplatesMasterProvider);
    if (evaluations.isLoading || templates.isLoading) {
      return const Center(child: ShadProgress());
    }
    if (evaluations.hasError || templates.hasError) {
      return const EvaluationMessage(message: EvaluationViewStrings.loadFailed);
    }
    return EvaluationPage(
      children: [
        const EvaluationHeading(text: EvaluationViewStrings.myEvaluations),
        CoachEvaluationGroups(
          evaluations: evaluations.requireValue.values,
          onOpen: onOpenEvaluation,
        ),
        const EvaluationHeading(text: EvaluationViewStrings.startNew),
        TemplateStartList(
          templates: templates.requireValue.values,
          onStart: (id) => start(context, id),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: ShadButton.outline(
            onPressed: onOpenTemplates,
            leading: const Icon(LucideIcons.layoutTemplate),
            child: const Text(EvaluationViewStrings.manageTemplates),
          ),
        ),
      ],
    );
  }
}
