import 'package:flutter/foundation.dart';

/// A form-local text value with optional per-language variants: the value a
/// translatable field of a club identity section form edits.
///
/// Owned by the form so it stays SDK-free; the host's adapter translates it
/// to and from the SDK's localized text at the boundary.
@immutable
class FormTranslatedText {
  const FormTranslatedText(this.defaultValue, [this.byLanguage = const {}]);

  /// The text shown when the viewer's language has no variant.
  final String defaultValue;

  /// Variants keyed by language code (`mr`, `hi`, …).
  final Map<String, String> byLanguage;

  /// True when there is neither a default nor any variant.
  bool get isEmpty => defaultValue.isEmpty && byLanguage.isEmpty;

  /// Every text trimmed, and variants that are then empty dropped.
  FormTranslatedText trimmed() => FormTranslatedText(defaultValue.trim(), {
    for (final entry in byLanguage.entries)
      if (entry.value.trim().isNotEmpty) entry.key: entry.value.trim(),
  });

  FormTranslatedText copyWith({
    String? defaultValue,
    Map<String, String>? byLanguage,
  }) {
    return FormTranslatedText(
      defaultValue ?? this.defaultValue,
      byLanguage ?? this.byLanguage,
    );
  }

  @override
  String toString() => 'FormTranslatedText($defaultValue, $byLanguage)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FormTranslatedText &&
        other.defaultValue == defaultValue &&
        mapEquals(other.byLanguage, byLanguage);
  }

  @override
  int get hashCode => Object.hash(
    defaultValue,
    Object.hashAllUnordered(
      byLanguage.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );
}
