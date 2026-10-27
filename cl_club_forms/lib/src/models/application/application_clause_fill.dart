import 'package:flutter/foundation.dart';

import 'application_clause_option.dart';
import 'application_fact_type.dart';

/// Fills library clause [clause] with the template's facts, [facts] naming
/// the fact that fills each gap (gap → fact name), for the editor to insert
/// as written text (club_client#336). The host makes the call; the form
/// stays SDK-free.
typedef ApplicationClauseFiller =
    Future<ApplicationClauseFill> Function(
      String clause,
      Map<String, String> facts,
    );

/// What filling a library clause gave: its text, or why it was refused.
@immutable
sealed class ApplicationClauseFill {
  const ApplicationClauseFill();
}

/// A clause filled in each library language.
final class ApplicationClauseFilled extends ApplicationClauseFill {
  const ApplicationClauseFilled({required this.text, this.heading = const {}});

  /// The filled sentence, by language code.
  final Map<String, String> text;

  /// A rule's heading, by language code; empty for the other kinds.
  final Map<String, String> heading;

  /// This fill with only the languages of [codes].
  ApplicationClauseFilled only(Iterable<String> codes) {
    final keep = codes.toSet();
    Map<String, String> pick(Map<String, String> texts) => {
      for (final entry in texts.entries)
        if (keep.contains(entry.key) && entry.value.trim().isNotEmpty)
          entry.key: entry.value.trim(),
    };
    return ApplicationClauseFilled(text: pick(text), heading: pick(heading));
  }
}

/// A fill refused, with the message shown under the clause list.
final class ApplicationClauseRefused extends ApplicationClauseFill {
  const ApplicationClauseRefused(this.message);

  /// What to tell the admin.
  final String message;
}

/// Which of the template's facts fills each gap of a clause.
@immutable
class ApplicationClauseFacts {
  const ApplicationClauseFacts({required this.bound, required this.missing});

  /// The facts of [clause]'s gaps among the template's [facts] (fact name
  /// → type). A gap takes the fact of its own name when that fact is of
  /// the gap's type; otherwise the template's only fact of that type. A
  /// gap with neither is [missing].
  factory ApplicationClauseFacts.bind(
    ApplicationClauseOption clause,
    Map<String, ApplicationFactType> facts,
  ) {
    final bound = <String, String>{};
    final missing = <String, ApplicationFactType>{};
    for (final MapEntry(key: gap, value: type) in clause.gaps.entries) {
      final ofType = [
        for (final entry in facts.entries)
          if (entry.value == type) entry.key,
      ];
      if (facts[gap] == type) {
        bound[gap] = gap;
      } else if (ofType.length == 1) {
        bound[gap] = ofType.single;
      } else {
        missing[gap] = type;
      }
    }
    return ApplicationClauseFacts(bound: bound, missing: missing);
  }

  /// The fact filling each gap, by gap name.
  final Map<String, String> bound;

  /// Each gap no fact fills, with the type it takes.
  final Map<String, ApplicationFactType> missing;
}
