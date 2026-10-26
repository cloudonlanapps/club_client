import 'package:flutter/foundation.dart';

import 'application_texts.dart';

/// A standard label of the form, as the label catalogue gives it: its id
/// and its text per language. Form-local; the host passes the catalogue.
@immutable
class ApplicationLabelOption {
  const ApplicationLabelOption({required this.id, required this.text});

  /// The label [id] as the catalogue's [json] gives it.
  factory ApplicationLabelOption.fromJson(String id, Object? json) =>
      ApplicationLabelOption(id: id, text: ApplicationTexts.of(json));

  /// The label's id (`field.full_name`).
  final String id;

  /// The label's text, by language code.
  final Map<String, String> text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApplicationLabelOption &&
          other.id == id &&
          mapEquals(other.text, text);

  @override
  int get hashCode => Object.hash(
    id,
    Object.hashAllUnordered(
      text.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );

  @override
  String toString() => 'ApplicationLabelOption(id: $id, text: $text)';
}
