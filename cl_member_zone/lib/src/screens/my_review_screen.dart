import 'dart:typed_data';

import 'package:cl_club_evaluation/cl_club_evaluation.dart'
    show EvaluationReadView;
import 'package:flutter/widgets.dart';

import '../widgets/evaluation_gate.dart';

/// One published review, read-only, at `/memberzone/reviews/mine/:id`
/// (club_core#174): the member reads their own; a coach may read a
/// member's by naming them in [username].
class MyReviewScreen extends StatelessWidget {
  /// A screen for review [evaluationId] of [username] (the viewer when
  /// null).
  const MyReviewScreen({
    required this.evaluationId,
    required this.onBack,
    required this.onOpenPdfBytes,
    required this.onHome,
    this.username,
    super.key,
  });

  /// The review's id.
  final int evaluationId;

  /// The member the review is about; the viewer when null.
  final String? username;

  /// Leaves the review.
  final VoidCallback onBack;

  /// Shows a PDF the view downloaded with the session — the stored member
  /// copy or evidence — as bytes.
  final ValueChanged<Uint8List> onOpenPdfBytes;

  /// Leaves a refused route for home.
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) => EvaluationGate(
    allows: (user) {
      final member = username;
      return member == null || member == user.username || user.roles.isCoach;
    },
    onHome: onHome,
    builder: (user) => EvaluationReadView(
      currentUser: user,
      username: username ?? user.username,
      evaluationId: evaluationId,
      onBack: onBack,
      onOpenPdfBytes: onOpenPdfBytes,
    ),
  );
}
