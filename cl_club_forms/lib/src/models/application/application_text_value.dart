import 'application_clause_text.dart';
import 'application_custom_text.dart';
import 'application_fact_text.dart';
import 'application_joined_text.dart';

/// A text an application prints, as its template holds it:
///
/// - [ApplicationCustomText], written in each print language;
/// - [ApplicationFactText], one of the template's facts on its own;
/// - [ApplicationClauseText], a clause of the library with its gaps bound
///   to facts;
/// - [ApplicationJoinedText], several of these on one line (a header item).
///
/// Form-local and SDK-free; [fromJson] and [toJson] read and write the
/// template's JSON as it is.
abstract class ApplicationTextValue {
  const ApplicationTextValue();

  /// The key naming a fact.
  static const String factKey = 'fact';

  /// The key naming a clause.
  static const String clauseKey = 'clause';

  /// The key of a clause's gap bindings.
  static const String argsKey = 'args';

  /// The text value [json] holds: a list is a joined line, a map with
  /// [clauseKey] or [factKey] a reference, any other map custom text. Null
  /// for nothing, or for custom text with no text in any language.
  static ApplicationTextValue? fromJson(Object? json) {
    if (json is List) {
      return ApplicationJoinedText([
        for (final part in json) ?fromJson(part),
      ]);
    }
    if (json is! Map) return null;
    if (json.containsKey(clauseKey)) {
      return ApplicationClauseText.fromJson(json);
    }
    if (json.containsKey(factKey)) return ApplicationFactText.fromJson(json);
    final custom = ApplicationCustomText.fromJson(json);
    return custom.text.isEmpty ? null : custom;
  }

  /// The value in the template's JSON.
  Object toJson();
}
