import 'package:flutter/foundation.dart';

import 'application_texts.dart';

/// A choice of the library's list that a fact of type `choices` may hold
/// (on-ice, inline, …): its id, what the fact stores, and its text per
/// language. Form-local; the host passes the library's choices.
@immutable
class ApplicationChoiceOption {
  const ApplicationChoiceOption({required this.id, required this.text});

  /// The choice [id] as the library's [json] gives it.
  factory ApplicationChoiceOption.fromJson(String id, Object? json) =>
      ApplicationChoiceOption(id: id, text: ApplicationTexts.of(json));

  /// What a fact stores for the choice.
  final String id;

  /// The choice's text, by language code.
  final Map<String, String> text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApplicationChoiceOption &&
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
  String toString() => 'ApplicationChoiceOption(id: $id, text: $text)';
}
