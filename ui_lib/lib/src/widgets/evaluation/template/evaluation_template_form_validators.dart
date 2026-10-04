import '../../../constants/evaluation_strings.dart';
import '../../../models/evaluation_layout_entry.dart';
import '../../../utils/evaluation_layout_ops.dart';
import '../../common_form_validators.dart';

/// Static, SDK-free validators of an evaluation template's name and layout.
abstract final class EvaluationTemplateFormValidators {
  /// The name: required, at least two characters.
  static String? name(String value) =>
      CommonFormValidators.name(value, label: EvaluationStrings.templateName);

  /// The layout: at least one question, and every section titled.
  static String? layout(List<EvaluationLayoutEntry> layout) {
    if (!EvaluationLayoutOps.hasQuestion(layout)) {
      return EvaluationStrings.questionNeeded;
    }
    return EvaluationLayoutOps.sectionsTitled(layout)
        ? null
        : EvaluationStrings.sectionTitleRequired;
  }
}
