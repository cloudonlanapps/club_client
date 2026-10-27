import '../../models/application/application_language_option.dart';
import '../../models/application/application_text_value.dart';
import '../event_marketing/marketing_values_equal.dart';
import 'application_form_fields.dart';

/// Reads and shapes the values of the application forms: what the host
/// passes in, as the template's JSON holds it, becomes what each form
/// holds, and that becomes what `validate()` returns.
abstract final class ApplicationFormValues {
  /// The name English is shown by when the host lists no name for it.
  static const String englishName = 'English';

  /// The print language beside English in [json], a template's
  /// `languages`; `''` when English is alone.
  static String otherLanguage(Object? json) => json is List
      ? json
                .whereType<String>()
                .where((code) => code != ApplicationFormFields.english)
                .firstOrNull ??
            ''
      : '';

  /// The template's `languages` for [other], the language beside English.
  static List<String> languagesOut(Object? other) => [
    ApplicationFormFields.english,
    if (other is String && other.isNotEmpty) other,
  ];

  /// The print languages for [other], each with its name from [options].
  static List<ApplicationLanguageOption> printLanguages(
    Object? other,
    List<ApplicationLanguageOption> options,
  ) => [
    for (final code in languagesOut(other))
      options.where((option) => option.code == code).firstOrNull ??
          ApplicationLanguageOption(
            code: code,
            name: code == ApplicationFormFields.english ? englishName : code,
          ),
  ];

  /// The printed text [json] holds, as the forms hold and return it: notes
  /// and empty languages left out; null for no text.
  static Object? text(Object? json) =>
      ApplicationTextValue.fromJson(json)?.toJson();

  /// A term as the forms hold it: its heading and body, an empty one left
  /// out.
  static Object? term(Object? json) {
    final map = json is Map ? json : const <Object?, Object?>{};
    return {
      for (final key in [
        ApplicationFormFields.headingKey,
        ApplicationFormFields.bodyKey,
      ])
        if (text(map[key]) case final Object value) key: value,
    };
  }

  /// The items of [json], a list, each shaped by [item].
  static List<Object?> list(Object? json, Object? Function(Object?) item) => [
    if (json is List)
      for (final entry in json) item(entry),
  ];

  /// Whether a form's [initial] and current [values] are the same, lists
  /// and maps compared item by item.
  static bool same(Map<String, dynamic> initial, Map<String, dynamic> values) =>
      marketingValuesEqual(initial, values);
}
