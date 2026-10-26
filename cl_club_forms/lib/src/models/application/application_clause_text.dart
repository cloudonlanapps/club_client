import 'package:flutter/foundation.dart';

import 'application_text_value.dart';

/// A clause of the library, its gaps filled with the template's facts.
@immutable
class ApplicationClauseText extends ApplicationTextValue {
  const ApplicationClauseText(this.clause, [this.args = const {}]);

  /// The clause reference [json] holds.
  factory ApplicationClauseText.fromJson(Map<Object?, Object?> json) {
    final clause = json[ApplicationTextValue.clauseKey];
    final args = json[ApplicationTextValue.argsKey];
    return ApplicationClauseText(clause is String ? clause : '', {
      if (args is Map)
        for (final entry in args.entries)
          if (entry.key case final String gap)
            if (entry.value case final String fact when fact.isNotEmpty)
              gap: fact,
    });
  }

  /// The clause's id; `''` while none is chosen.
  final String clause;

  /// The fact that fills each gap, by gap name; a gap with none is absent.
  final Map<String, String> args;

  @override
  Map<String, Object> toJson() => {
    ApplicationTextValue.clauseKey: clause,
    if (args.isNotEmpty) ApplicationTextValue.argsKey: Map.of(args),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApplicationClauseText &&
          other.clause == clause &&
          mapEquals(other.args, args);

  @override
  int get hashCode => Object.hash(
    clause,
    Object.hashAllUnordered(
      args.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );

  @override
  String toString() => 'ApplicationClauseText($clause, $args)';
}
