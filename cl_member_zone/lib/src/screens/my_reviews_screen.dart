import 'package:cl_club_evaluation/cl_club_evaluation.dart' show MyReviewsView;
import 'package:flutter/widgets.dart';

import '../widgets/evaluation_gate.dart';

/// The member's published reviews at `/memberzone/reviews/mine`
/// (club_core#174): open to every member while evaluations are on.
class MyReviewsScreen extends StatelessWidget {
  /// A screen that opens a review through [onOpen].
  const MyReviewsScreen({
    required this.onOpen,
    required this.onHome,
    super.key,
  });

  /// Opens the review with this id.
  final ValueChanged<int> onOpen;

  /// Leaves a refused route for home.
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) => EvaluationGate(
    allows: (_) => true,
    onHome: onHome,
    builder: (user) => MyReviewsView(currentUser: user, onOpen: onOpen),
  );
}
