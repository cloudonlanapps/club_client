import 'dart:typed_data';

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
import '../widgets/evaluation_edit_body.dart';
import '../widgets/evaluation_message.dart';

/// The owner's editor of one evaluation (design 4.2, `reviews/:id`):
/// **Back** (no confirmation — answers autosave); a head with the member,
/// the review's title and a stamp (Ready once finalized, Published once
/// published); the Review Period section, its pencil on a draft; one
/// answer field per question, written as each settles, with a coach note
/// and evidence where the item allows, the closing Q & As last in one
/// untitled card; **Review Management** with the actions its status offers —
/// a draft Finalize and Delete, a finalized one Publish, Revert to draft
/// and Transfer, a published one Unpublish — and **Review Info**. A
/// reopened draft shows its gaps at once. Finalized and published
/// evaluations show read-only, private items greyed; a published one
/// offers its member copy from the download icon at the top right.
/// Evidence and the member copy are private: requests send the session's
/// headers, and a PDF is downloaded with the session and goes to
/// [onOpenPdfBytes] as bytes.
///
/// Only the effective owner can load it; for anyone else it is not
/// available. Renders nothing unless the server runs evaluations.
class EvaluationEditView extends ConsumerWidget {
  /// Evaluation [evaluationId], for [currentUser], a coach.
  const EvaluationEditView({
    required this.currentUser,
    required this.evaluationId,
    required this.onBack,
    required this.onDeleted,
    required this.onTransferred,
    required this.onOpenPdfBytes,
    super.key,
  });

  /// The signed-in coach.
  final UserPrivate currentUser;

  /// The evaluation.
  final int evaluationId;

  /// Leaves the view.
  final VoidCallback onBack;

  /// Called once the draft is deleted.
  final VoidCallback onDeleted;

  /// Called once the evaluation is handed to another coach.
  final VoidCallback onTransferred;

  /// Shows a downloaded PDF as bytes: the stored member copy or evidence.
  final ValueChanged<Uint8List> onOpenPdfBytes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    assert(
      currentUser.roles.isCoach,
      'EvaluationEditView called for ${currentUser.username}, who is not a '
      'coach. Screen gate failed.',
    );
    if (ref.watch(evaluationsProvider) != true) return const SizedBox.shrink();
    final evaluations = ref.watch(clEvaluationsMasterProvider);
    final templates = ref.watch(clEvaluationTemplatesMasterProvider);
    if (evaluations.isLoading || templates.isLoading) {
      return const Center(child: ShadProgress());
    }
    final evaluation = evaluations.valueOrNull?[evaluationId];
    final template = templates.valueOrNull?[evaluation?.templateId];
    if (evaluations.hasError || templates.hasError) {
      return EvaluationMessage(
        message: EvaluationViewStrings.loadFailed,
        onBack: onBack,
      );
    }
    if (evaluation == null ||
        evaluation.deletedAtUtc != null ||
        template == null) {
      return EvaluationMessage(
        message: EvaluationViewStrings.evaluationMissing,
        onBack: onBack,
      );
    }
    return EvaluationEditBody(
      evaluation: evaluation,
      template: template,
      onBack: onBack,
      onDeleted: onDeleted,
      onTransferred: onTransferred,
      onOpenPdfBytes: onOpenPdfBytes,
    );
  }
}
