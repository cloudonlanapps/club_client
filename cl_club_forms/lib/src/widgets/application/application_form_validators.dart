import '../../models/application/application_custom_text.dart';
import '../../models/application/application_joined_text.dart';
import '../../models/application/application_text_value.dart';
import 'application_fact_validators.dart';
import 'application_form_fields.dart';
import 'application_form_strings.dart';

/// Checks of the application forms. Each returns `null` when what it
/// checks is fine, or the message of its first problem. They check what a
/// draft must hold to make sense; whether every print language is there is
/// for save (`ApplicationCompleteness`).
abstract final class ApplicationFormValidators {
  /// A printed text, [json] as the template's JSON holds it or an
  /// [ApplicationTextValue]: it needs English, each part of a joined line
  /// too. Nothing is fine unless [required].
  static String? text(Object? json, {bool required = false}) {
    final value = json is ApplicationTextValue
        ? json
        : ApplicationTextValue.fromJson(json);
    return switch (value) {
      null => required ? ApplicationFormStrings.englishRequired : null,
      ApplicationCustomText(:final text) =>
        (text[ApplicationFormFields.english] ?? '').isEmpty
            ? ApplicationFormStrings.englishRequired
            : null,
      ApplicationJoinedText(:final parts) =>
        parts.isEmpty && required
            ? ApplicationFormStrings.englishRequired
            : parts.map((part) => text(part.toJson())).nonNulls.firstOrNull,
      _ => null,
    };
  }

  /// Each of [items] by [each]; the first problem is named by its item's
  /// place, the item called [noun].
  static String? items(
    List<Object?>? items,
    String noun,
    String? Function(Object? item) each,
  ) {
    final list = items ?? const [];
    for (var i = 0; i < list.length; i++) {
      final problem = each(list[i]);
      if (problem != null) {
        return ApplicationFormStrings.aboutItem(noun, i + 1, problem);
      }
    }
    return null;
  }

  /// The facts, each a row of name, type and value: see
  /// `ApplicationFactValidators`.
  static String? facts(List<Object?>? rows) {
    final seen = <String>{};
    return items(rows, ApplicationFormStrings.factNoun, (row) {
      final map = row is Map ? row : const <Object?, Object?>{};
      final name = map[ApplicationFormFields.nameKey];
      final problem = ApplicationFactValidators.name(name);
      if (problem != null) return problem;
      if (!seen.add(name! as String)) {
        return ApplicationFormStrings.factNameTwice(name as String);
      }
      return ApplicationFactValidators.value(map);
    });
  }

  /// An age category: an English name and, when its age limit is ticked,
  /// at least one birth date, the two in order.
  static String? ageCategory(Object? item) {
    final map = item is Map ? item : const <Object?, Object?>{};
    final label = ApplicationCustomText.fromJson(
      map[ApplicationFormFields.labelKey],
    ).text;
    if ((label[ApplicationFormFields.english] ?? '').isEmpty) {
      return ApplicationFormStrings.nameEnglishRequired;
    }
    final after = map[ApplicationFormFields.bornOnOrAfterKey];
    final before = map[ApplicationFormFields.bornOnOrBeforeKey];
    if (map[ApplicationFormFields.ageLimitKey] == true &&
        after is! String &&
        before is! String) {
      return ApplicationFormStrings.birthDateRequired;
    }
    if (after is String && before is String && before.compareTo(after) < 0) {
      return ApplicationFormStrings.birthOrder;
    }
    return null;
  }

  /// A term: a heading and a text, both with English.
  static String? term(Object? item) {
    final map = item is Map ? item : const <Object?, Object?>{};
    return part(
          ApplicationFormStrings.heading,
          text(map[ApplicationFormFields.headingKey], required: true),
        ) ??
        part(
          ApplicationFormStrings.text,
          text(map[ApplicationFormFields.bodyKey], required: true),
        );
  }

  /// A note under the terms: its text, with English; and its attribution,
  /// optional.
  static String? note(Object? item) {
    final map = item is Map ? item : const <Object?, Object?>{};
    return text(map[ApplicationFormFields.textKey], required: true) ??
        part(
          ApplicationFormStrings.attribution,
          text(map[ApplicationFormFields.attributionKey]),
        );
  }

  /// [problem] about the part labelled [label]; null when there is none.
  static String? part(String label, String? problem) =>
      problem == null ? null : ApplicationFormStrings.aboutPart(label, problem);

  /// An English text typed in a plain input: the title of a new
  /// application.
  static String? englishText(String? value) => (value ?? '').trim().isEmpty
      ? ApplicationFormStrings.englishRequired
      : null;

  /// A standard label's text in one language.
  static String? label(String? value) => (value ?? '').trim().isEmpty
      ? ApplicationFormStrings.labelRequired
      : null;
}
