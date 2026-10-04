import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show EvaluationItemValue;

import '../constants/evaluation_view_sizes.dart';
import '../constants/evaluation_view_strings.dart';
import 'existing_question_picker.dart';

/// Picks a question of any template to copy ("Existing question", design
/// 1.2); resolves to the copy — no id, its origin set — or `null`.
Future<EvaluationItemValue?> showExistingQuestionDialog(BuildContext context) =>
    showShadDialog<EvaluationItemValue>(
      context: context,
      builder: (dialogContext) => ShadDialog(
        title: const Text(EvaluationViewStrings.existingQuestion),
        constraints: const BoxConstraints(
          maxWidth: EvaluationViewSizes.dialogWidth,
        ),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(EvaluationViewStrings.cancel),
          ),
        ],
        child: ExistingQuestionPicker(
          onPicked: (copy) => Navigator.of(dialogContext).pop(copy),
        ),
      ),
    );
