import 'package:cl_club_evaluation/cl_club_evaluation.dart'
    show TemplateCreateView;
import 'package:flutter/widgets.dart';

import '../widgets/evaluation_gate.dart';

/// The evaluation template designer at `/memberzone/reviews/templates/new`
/// (club_core#174): coaches and admins. Given [copyOfTemplateId]
/// (**Duplicate**), it opens pre-filled with a copy of that template; given
/// [initialValues] (**Import**), pre-filled with them.
class TemplateCreateScreen extends StatelessWidget {
  /// A screen forwarding the designer's callbacks.
  const TemplateCreateScreen({
    required this.onCreated,
    required this.onCancel,
    required this.onHome,
    this.copyOfTemplateId,
    this.initialValues,
    super.key,
  });

  /// The template to start from as a copy; a blank template when `null`.
  final int? copyOfTemplateId;

  /// The designer's initial values, read from an imported template file.
  final Map<String, dynamic>? initialValues;

  /// Called with the new template's id.
  final ValueChanged<int> onCreated;

  /// Leaves the designer without creating.
  final VoidCallback onCancel;

  /// Leaves a refused route for home.
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) => EvaluationGate(
    allows: (user) => user.roles.isCoach || user.isAdmin,
    onHome: onHome,
    builder: (user) => TemplateCreateView(
      currentUser: user,
      copyOfTemplateId: copyOfTemplateId,
      initialValues: initialValues,
      onCreated: onCreated,
      onCancel: onCancel,
    ),
  );
}
