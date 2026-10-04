import 'dart:typed_data';

import 'package:cl_club_evaluation/cl_club_evaluation.dart'
    show EvaluationEditView;
import 'package:flutter/widgets.dart';

import '../widgets/evaluation_gate.dart';

/// The owner's editor for one evaluation at `/memberzone/reviews/:id`
/// (club_core#174): coaches only — the server shows an evaluation to its
/// effective owner alone.
class ReviewEditScreen extends StatelessWidget {
  /// A screen for evaluation [evaluationId].
  const ReviewEditScreen({
    required this.evaluationId,
    required this.onBack,
    required this.onDeleted,
    required this.onTransferred,
    required this.onOpenPdfBytes,
    required this.onHome,
    super.key,
  });

  /// The evaluation's id.
  final int evaluationId;

  /// Leaves the editor.
  final VoidCallback onBack;

  /// Called once the evaluation is deleted.
  final VoidCallback onDeleted;

  /// Called once the evaluation is handed to another coach.
  final VoidCallback onTransferred;

  /// Shows a PDF the view downloaded with the session — the stored member
  /// copy or evidence — as bytes.
  final ValueChanged<Uint8List> onOpenPdfBytes;

  /// Leaves a refused route for home.
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) => EvaluationGate(
    allows: (user) => user.roles.isCoach,
    onHome: onHome,
    builder: (user) => EvaluationEditView(
      currentUser: user,
      evaluationId: evaluationId,
      onBack: onBack,
      onDeleted: onDeleted,
      onTransferred: onTransferred,
      onOpenPdfBytes: onOpenPdfBytes,
    ),
  );
}
