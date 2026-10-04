import 'package:cl_club_evaluation/cl_club_evaluation.dart'
    show TemplateLibraryView;
import 'package:flutter/widgets.dart';

import '../widgets/evaluation_gate.dart';

/// The evaluation template library at `/memberzone/reviews/templates`
/// (club_core#174): coaches and admins. A coach reaches it from the coach
/// view's **Manage Templates**; an admin who does not coach gets the same
/// library at `/memberzone/reviews`.
class TemplateLibraryScreen extends StatelessWidget {
  /// A screen forwarding the library's callbacks.
  const TemplateLibraryScreen({
    required this.onOpenTemplate,
    required this.onCreateTemplate,
    required this.onDuplicateTemplate,
    required this.onHome,
    super.key,
  });

  /// Opens the template with this id.
  final ValueChanged<int> onOpenTemplate;

  /// Opens the template designer.
  final VoidCallback onCreateTemplate;

  /// Opens the designer pre-filled with a copy of the template with this
  /// id.
  final ValueChanged<int> onDuplicateTemplate;

  /// Leaves a refused route for home.
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) => EvaluationGate(
    allows: (user) => user.roles.isCoach || user.isAdmin,
    onHome: onHome,
    builder: (user) => TemplateLibraryView(
      currentUser: user,
      onOpenTemplate: onOpenTemplate,
      onCreateTemplate: onCreateTemplate,
      onDuplicateTemplate: onDuplicateTemplate,
    ),
  );
}
