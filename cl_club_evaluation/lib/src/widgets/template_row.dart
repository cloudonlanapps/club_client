import 'package:club_sdk_2/club_sdk_2.dart' show EvaluationTemplate;
import 'package:flutter/widgets.dart';
import 'package:ui_lib/ui_lib.dart' show ActionItem, EntityCard, EntityImage;

import '../constants/evaluation_view_strings.dart';
import '../utils/evaluation_initial.dart';

/// One template of the library: its name, how many questions it asks and,
/// as plain text, whether an evaluation uses it, with the host's
/// [actions].
class TemplateRow extends StatelessWidget {
  /// A row for [template].
  const TemplateRow({
    required this.template,
    this.onTap,
    this.actions,
    super.key,
  });

  /// The template.
  final EvaluationTemplate template;

  /// Opens it, when the viewer may.
  final VoidCallback? onTap;

  /// The row's actions, the first inline.
  final List<ActionItem>? actions;

  @override
  Widget build(BuildContext context) {
    final questions = template.items.where((i) => i.type.isQuestion).length;
    return EntityCard(
      image: EntityImage.initials(evaluationInitial(template.name)),
      title: template.name,
      caption: [
        EvaluationViewStrings.questionCount(questions),
        if (template.inUse) EvaluationViewStrings.inUse,
      ].join(EvaluationViewStrings.separator),
      trailingActions: actions,
      onTap: onTap,
    );
  }
}
