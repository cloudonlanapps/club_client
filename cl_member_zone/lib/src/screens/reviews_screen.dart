import 'package:cl_club_evaluation/cl_club_evaluation.dart'
    show CoachReviewsView, TemplateLibraryView;
import 'package:flutter/widgets.dart';

import '../widgets/evaluation_gate.dart';

/// The staff reviews page at `/memberzone/reviews` (club_core#174, design
/// 4.1): a coach — an admin who coaches included — gets their evaluations,
/// the templates to start from and **Manage Templates** ([onOpenTemplates])
/// to reach the template library; an admin who does not coach gets the
/// template library. Anyone else is refused.
class ReviewsScreen extends StatelessWidget {
  /// A screen forwarding each view's callbacks.
  const ReviewsScreen({
    required this.onOpenEvaluation,
    required this.onOpenTemplate,
    required this.onCreateTemplate,
    required this.onDuplicateTemplate,
    required this.onOpenTemplates,
    required this.onHome,
    super.key,
  });

  /// Opens the coach's evaluation with this id.
  final ValueChanged<int> onOpenEvaluation;

  /// Opens the template with this id (the admin's library).
  final ValueChanged<int> onOpenTemplate;

  /// Opens the template designer (the admin's library).
  final VoidCallback onCreateTemplate;

  /// Opens the designer pre-filled with a copy of the template with this
  /// id (the admin's library).
  final ValueChanged<int> onDuplicateTemplate;

  /// Opens the template library from the coach view.
  final VoidCallback onOpenTemplates;

  /// Leaves a refused route for home.
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) => EvaluationGate(
    allows: (user) => user.roles.isCoach || user.isAdmin,
    onHome: onHome,
    builder: (user) => user.roles.isCoach
        ? CoachReviewsView(
            currentUser: user,
            onOpenEvaluation: onOpenEvaluation,
            onOpenTemplates: onOpenTemplates,
          )
        : TemplateLibraryView(
            currentUser: user,
            onOpenTemplate: onOpenTemplate,
            onCreateTemplate: onCreateTemplate,
            onDuplicateTemplate: onDuplicateTemplate,
          ),
  );
}
