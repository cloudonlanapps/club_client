import 'package:flutter/foundation.dart';

import 'application_text_value.dart';
import 'application_texts.dart';

/// A text written for the template, by language code. A language the form
/// does not show is kept as it is.
@immutable
class ApplicationCustomText extends ApplicationTextValue {
  const ApplicationCustomText(this.text);

  /// The custom text [json] holds; see `ApplicationTexts.of`.
  factory ApplicationCustomText.fromJson(Object? json) =>
      ApplicationCustomText(ApplicationTexts.of(json));

  /// No text yet: what a new item starts from.
  static const ApplicationCustomText none = ApplicationCustomText({});

  /// The text, by language code, trimmed and none empty.
  final Map<String, String> text;

  @override
  Map<String, String> toJson() => Map.of(text);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApplicationCustomText && mapEquals(other.text, text);

  @override
  int get hashCode => Object.hashAllUnordered(
    text.entries.map((e) => Object.hash(e.key, e.value)),
  );

  @override
  String toString() => 'ApplicationCustomText($text)';
}
