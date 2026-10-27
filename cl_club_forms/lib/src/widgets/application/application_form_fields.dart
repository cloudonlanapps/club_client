/// Field ids of the application forms, and the keys of what their lists
/// hold. Each id is the template's own JSON key, so what a form's
/// `validate()` returns is a part of the template as it is stored.
abstract final class ApplicationFormFields {
  /// The print languages (`List<String>`): `['en']` or `['en', other]`.
  static const String languagesId = 'languages';

  /// The organisation the form is addressed to: custom text.
  static const String organisationId = 'organisation';

  /// The title: custom text.
  static const String titleId = 'title';

  /// The subtitle: custom text or a fact; optional.
  static const String subtitleId = 'subtitle';

  /// The closing line under the signatures: custom text; optional.
  static const String formFooterId = 'form_footer';

  /// The facts (`Map<String, Map>`), by name: each its [typeKey] and its
  /// value, under [valueKey] or, for a range, [fromKey] and [toKey].
  static const String factsId = 'facts';

  /// The header items (`List`): each a text value or a joined list.
  static const String headerId = 'header';

  /// The age categories (`List<Map>`).
  static const String ageCategoriesId = 'age_categories';

  /// The additional selections (`List`): each a text value.
  static const String selectionsId = 'selections';

  /// The declaration above the signatures: a text value.
  static const String declarationId = 'declaration';

  /// The terms (`List<Map>`): each a clause reference, or [headingKey] and
  /// [bodyKey] as custom text.
  static const String termsId = 'terms';

  /// The notes under the terms (`List<Map>`): each [textKey] and, maybe,
  /// [attributionKey].
  static const String termsNotesId = 'terms_notes';

  /// The label overrides (`Map<String, Map<String, String>>`), by label id.
  static const String labelOverridesId = 'label_overrides';

  /// A fact's name, while the facts form holds it as a row.
  static const String nameKey = 'name';

  /// A fact's type.
  static const String typeKey = 'type';

  /// A fact's value.
  static const String valueKey = 'value';

  /// A range's first day.
  static const String fromKey = 'from';

  /// A range's last day.
  static const String toKey = 'to';

  /// A custom term's heading.
  static const String headingKey = 'heading';

  /// A custom term's body.
  static const String bodyKey = 'body';

  /// A note's text.
  static const String textKey = 'text';

  /// A note's attribution.
  static const String attributionKey = 'attribution';

  /// An age category's name.
  static const String labelKey = 'label';

  /// Whether an age category limits the birth dates it takes: the
  /// editor's "Age limit applicable" tick. The form keeps it beside the
  /// dates; the template stores only the dates, sent while it is ticked.
  static const String ageLimitKey = 'age_limit';

  /// The first birth date an age category takes.
  static const String bornOnOrAfterKey = 'born_on_or_after';

  /// The last birth date an age category takes.
  static const String bornOnOrBeforeKey = 'born_on_or_before';

  /// The genders an age category takes; absent for every gender.
  static const String gendersKey = 'genders';

  /// The language every application is printed in, and every text needs.
  static const String english = 'en';

  /// Separates a label's id from a language code in the labels form's
  /// field ids. Label ids hold `.`, so that form reads no nesting in ids.
  static const String labelLanguageSeparator = '@';

  /// The labels form's field id of [label]'s text in [code].
  static String labelFieldId(String label, String code) =>
      '$label$labelLanguageSeparator$code';
}
