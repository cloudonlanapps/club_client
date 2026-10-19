import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/evaluation_view_strings.dart';
import 'evaluation_title_bar.dart';

/// The template designer's title bar: "New template" with **Cancel** and
/// **Create**, both off while the template is being created.
class TemplateCreateTitleBar extends StatelessWidget {
  /// The title bar; [creating] turns its buttons off.
  const TemplateCreateTitleBar({
    required this.creating,
    required this.onCancel,
    required this.onCreate,
    super.key,
  });

  /// Whether the template is being created.
  final bool creating;

  /// Leaves without creating.
  final VoidCallback onCancel;

  /// Creates the template.
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => EvaluationTitleBar(
    title: EvaluationViewStrings.newTemplate,
    actions: [
      ShadButton.outline(
        onPressed: creating ? null : onCancel,
        child: const Text(EvaluationViewStrings.cancel),
      ),
      ShadButton(
        onPressed: creating ? null : onCreate,
        child: Text(
          creating
              ? EvaluationViewStrings.creating
              : EvaluationViewStrings.create,
        ),
      ),
    ],
  );
}
