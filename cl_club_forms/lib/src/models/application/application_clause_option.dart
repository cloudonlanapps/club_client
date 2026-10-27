import 'package:flutter/foundation.dart';

import 'application_clause_kind.dart';

/// A library text, as an application's editor offers it (club_client#336,
/// #389): a built-in clause of the server's library or one of the club's
/// own texts, written in each language with its `{fact}` gaps. Tapping it
/// pastes the text as written. Form-local; the host passes the list.
@immutable
class ApplicationClauseOption {
  const ApplicationClauseOption({
    required this.id,
    required this.kind,
    required this.text,
    this.heading = const {},
    this.name,
    this.club = false,
  });

  /// What tells it apart from the others in the list: a built-in clause's
  /// key (`rule.matches`), or the host's id of a club text.
  final String id;

  /// Where it may be used.
  final ApplicationClauseKind kind;

  /// A rule's heading, by language code; empty for the other kinds.
  final Map<String, String> heading;

  /// The text, by language code, with its gaps in braces.
  final Map<String, String> text;

  /// A club text's short name; null for a built-in clause.
  final String? name;

  /// Whether it is one of the club's own texts rather than a built-in one.
  final bool club;

  /// This option with only those languages of [codes] that have text, each
  /// trimmed: what is pasted into a template printing in [codes].
  ApplicationClauseOption only(Iterable<String> codes) {
    final keep = codes.toSet();
    Map<String, String> pick(Map<String, String> texts) => {
      for (final entry in texts.entries)
        if (keep.contains(entry.key) && entry.value.trim().isNotEmpty)
          entry.key: entry.value.trim(),
    };
    return ApplicationClauseOption(
      id: id,
      kind: kind,
      text: pick(text),
      heading: pick(heading),
      name: name,
      club: club,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApplicationClauseOption &&
          other.id == id &&
          other.kind == kind &&
          other.name == name &&
          other.club == club &&
          mapEquals(other.heading, heading) &&
          mapEquals(other.text, text);

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    name,
    club,
    Object.hashAllUnordered(
      heading.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    Object.hashAllUnordered(
      text.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );

  @override
  String toString() => 'ApplicationClauseOption(id: $id, kind: $kind)';
}
