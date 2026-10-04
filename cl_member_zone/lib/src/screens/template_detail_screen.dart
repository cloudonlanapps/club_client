import 'package:cl_club_evaluation/cl_club_evaluation.dart'
    show TemplateDetailView;
import 'package:flutter/widgets.dart';

import '../widgets/evaluation_gate.dart';

/// One evaluation template, edited section by section, at
/// `/memberzone/reviews/templates/:id` (club_core#174): coaches and admins.
class TemplateDetailScreen extends StatelessWidget {
  /// A screen for template [templateId].
  const TemplateDetailScreen({
    required this.templateId,
    required this.onBack,
    required this.onDuplicate,
    required this.onHome,
    super.key,
  });

  /// The template's id.
  final int templateId;

  /// Leaves the template (also once it is deleted).
  final VoidCallback onBack;

  /// Opens the designer pre-filled with a copy of the template with this
  /// id.
  final ValueChanged<int> onDuplicate;

  /// Leaves a refused route for home.
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) => EvaluationGate(
    allows: (user) => user.roles.isCoach || user.isAdmin,
    onHome: onHome,
    builder: (user) => TemplateDetailView(
      currentUser: user,
      templateId: templateId,
      onBack: onBack,
      onDuplicate: onDuplicate,
    ),
  );
}
