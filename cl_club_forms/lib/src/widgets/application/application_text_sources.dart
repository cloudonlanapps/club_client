import 'package:flutter/foundation.dart';

import '../../models/application/application_clause_kind.dart';
import '../../models/application/application_clause_option.dart';
import '../../models/application/application_fact_type.dart';

/// What a text of an application may refer to: the template's facts and
/// the library's clauses. The forms build it from what the host passes.
@immutable
class ApplicationTextSources {
  ApplicationTextSources({
    this.facts = const {},
    List<ApplicationClauseOption> clauses = const [],
  }) : clauses = {for (final clause in clauses) clause.id: clause};

  /// The template's facts: the type of each, by name, in order.
  final Map<String, ApplicationFactType> facts;

  /// The library's clauses, by id, in order.
  final Map<String, ApplicationClauseOption> clauses;

  /// The clauses of [kind], in the library's order.
  List<ApplicationClauseOption> clausesOf(ApplicationClauseKind? kind) => [
    for (final clause in clauses.values)
      if (kind == null || clause.kind == kind) clause,
  ];

  /// The names of the facts of [type], or of every fact when it is null.
  List<String> factsOf(ApplicationFactType? type) => [
    for (final entry in facts.entries)
      if (type == null || entry.value == type) entry.key,
  ];
}
