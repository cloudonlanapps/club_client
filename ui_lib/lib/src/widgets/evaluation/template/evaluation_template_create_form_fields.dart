/// Field ids of `EvaluationTemplateCreateForm`, and so the keys of its
/// initial values: [nameId] `String`, [layoutId]
/// `List<EvaluationLayoutEntry>` (items inline).
abstract final class EvaluationTemplateCreateFormFields {
  /// The template's name.
  static const String nameId = 'name';

  /// The template's items and sections.
  static const String layoutId = 'layout';
}
