import '../../models/application/application_clause_text.dart';
import '../../models/application/application_custom_text.dart';
import '../../models/application/application_fact_text.dart';
import '../../models/application/application_text_value.dart';

/// Where a printed text comes from, as its editor offers the choice.
enum ApplicationTextMode {
  /// A clause of the library.
  clause,

  /// One of the template's facts.
  fact,

  /// Written in each print language.
  custom;

  /// The mode of [value]; null for none, or for a joined line.
  static ApplicationTextMode? of(ApplicationTextValue? value) =>
      switch (value) {
        ApplicationClauseText() => clause,
        ApplicationFactText() => fact,
        ApplicationCustomText() => custom,
        _ => null,
      };
}
