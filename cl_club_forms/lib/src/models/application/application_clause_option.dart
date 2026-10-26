import 'package:flutter/foundation.dart';

import 'application_clause_kind.dart';
import 'application_fact_type.dart';
import 'application_texts.dart';

/// A clause of the library, as an application's editor offers it: a
/// sentence in each language with gaps (`{dates}`) that a template fills
/// with its facts. Form-local; the host passes the library.
@immutable
class ApplicationClauseOption {
  const ApplicationClauseOption({
    required this.id,
    required this.kind,
    required this.text,
    this.heading = const {},
    this.gaps = const {},
  });

  /// The clause [id] as the library's [json] gives it. A clause of no
  /// known kind is taken for a note; a gap of no known type is left out.
  factory ApplicationClauseOption.fromJson(
    String id,
    Map<Object?, Object?> json,
  ) {
    final gaps = json[gapsKey];
    return ApplicationClauseOption(
      id: id,
      kind:
          ApplicationClauseKind.fromJson(json[kindKey]) ??
          ApplicationClauseKind.note,
      heading: ApplicationTexts.of(json[headingKey]),
      text: ApplicationTexts.of(json[textKey]),
      gaps: {
        if (gaps is Map)
          for (final entry in gaps.entries)
            if (entry.key case final String gap)
              if (ApplicationFactType.fromJson(entry.value)
                  case final ApplicationFactType type)
                gap: type,
      },
    );
  }

  /// The key of a clause's kind in the library's JSON.
  static const String kindKey = 'kind';

  /// The key of a clause's gaps.
  static const String gapsKey = 'gaps';

  /// The key of a rule's heading.
  static const String headingKey = 'heading';

  /// The key of a clause's text.
  static const String textKey = 'text';

  /// The clause's id (`rule.matches`).
  final String id;

  /// Where the clause may be used.
  final ApplicationClauseKind kind;

  /// A rule's heading, by language code; empty for the other kinds.
  final Map<String, String> heading;

  /// The sentence, by language code, with its gaps in braces.
  final Map<String, String> text;

  /// The type of fact each gap takes, by gap name.
  final Map<String, ApplicationFactType> gaps;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApplicationClauseOption &&
          other.id == id &&
          other.kind == kind &&
          mapEquals(other.heading, heading) &&
          mapEquals(other.text, text) &&
          mapEquals(other.gaps, gaps);

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    Object.hashAllUnordered(
      heading.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    Object.hashAllUnordered(
      text.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    Object.hashAllUnordered(
      gaps.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );

  @override
  String toString() => 'ApplicationClauseOption(id: $id, kind: $kind)';
}
