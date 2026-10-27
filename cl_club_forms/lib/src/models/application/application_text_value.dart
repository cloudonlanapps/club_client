import 'application_custom_text.dart';
import 'application_joined_text.dart';

/// A text an application prints, as its template holds it:
///
/// - [ApplicationCustomText], written in each print language;
/// - [ApplicationJoinedText], several of these on one line (a header item).
///
/// Form-local and SDK-free; [fromJson] and [toJson] read and write the
/// template's JSON as it is.
abstract class ApplicationTextValue {
  const ApplicationTextValue();

  /// The text value [json] holds: a list is a joined line, a map custom
  /// text. Null for nothing, or for custom text with no text in any
  /// language.
  static ApplicationTextValue? fromJson(Object? json) {
    if (json is List) {
      return ApplicationJoinedText([
        for (final part in json) ?fromJson(part),
      ]);
    }
    if (json is! Map) return null;
    final custom = ApplicationCustomText.fromJson(json);
    return custom.text.isEmpty ? null : custom;
  }

  /// The value in the template's JSON.
  Object toJson();
}
