import '../../models/application/application_clause_kind.dart';
import '../../models/application/application_clause_text.dart';
import '../../models/application/application_custom_text.dart';
import '../../models/application/application_fact_text.dart';
import '../../models/application/application_joined_text.dart';
import '../../models/application/application_text_value.dart';
import 'application_fact_validators.dart';
import 'application_form_fields.dart';
import 'application_form_strings.dart';
import 'application_text_sources.dart';

/// Checks of the application forms. Each returns `null` when what it
/// checks is fine, or the message of its first problem. They check what a
/// draft must hold to make sense; whether every print language is there is
/// for save (`ApplicationCompleteness`).
abstract final class ApplicationFormValidators {
  /// A printed text, [json] as the template's JSON holds it or an
  /// [ApplicationTextValue]: custom text
  /// needs English; a fact must be one of [sources]; a clause must be one
  /// of the library, of [kind] when given, with each gap bound to a fact
  /// of the gap's type. Nothing is fine unless [required].
  static String? text(
    Object? json,
    ApplicationTextSources sources, {
    bool required = false,
    ApplicationClauseKind? kind,
  }) {
    final value = json is ApplicationTextValue
        ? json
        : ApplicationTextValue.fromJson(json);
    return switch (value) {
      null => required ? ApplicationFormStrings.englishRequired : null,
      ApplicationCustomText(:final text) =>
        (text[ApplicationFormFields.english] ?? '').isEmpty
            ? ApplicationFormStrings.englishRequired
            : null,
      ApplicationFactText(:final fact) => factRef(fact, sources),
      ApplicationClauseText() => clause(value, sources, kind),
      ApplicationJoinedText(:final parts) =>
        parts.isEmpty && required
            ? ApplicationFormStrings.englishRequired
            : parts
                  .map((part) => text(part.toJson(), sources, kind: kind))
                  .nonNulls
                  .firstOrNull,
      _ => null,
    };
  }

  /// A reference to the fact named [fact].
  static String? factRef(String fact, ApplicationTextSources sources) {
    if (fact.isEmpty) return ApplicationFormStrings.chooseFact;
    if (!sources.facts.containsKey(fact)) {
      return ApplicationFormStrings.noSuchFact(fact);
    }
    return null;
  }

  /// A reference to a clause of [kind], or of any kind when it is null.
  static String? clause(
    ApplicationClauseText value,
    ApplicationTextSources sources,
    ApplicationClauseKind? kind,
  ) {
    if (value.clause.isEmpty) return ApplicationFormStrings.chooseClause;
    final option = sources.clauses[value.clause];
    if (option == null) {
      return ApplicationFormStrings.noSuchClause(value.clause);
    }
    if (kind != null && option.kind != kind) {
      return ApplicationFormStrings.wrongKind(value.clause);
    }
    for (final MapEntry(key: gap, value: type) in option.gaps.entries) {
      final fact = value.args[gap];
      if (fact == null) return ApplicationFormStrings.gapUnbound(gap);
      final problem = factRef(fact, sources);
      if (problem != null) return problem;
      if (sources.facts[fact] != type) {
        return ApplicationFormStrings.gapWrongType(gap, fact, type);
      }
    }
    return null;
  }

  /// Each of [items] by [each]; the first problem is named by its item's
  /// place, the item called [noun].
  static String? items(
    List<Object?>? items,
    String noun,
    String? Function(Object? item) each,
  ) {
    final list = items ?? const [];
    for (var i = 0; i < list.length; i++) {
      final problem = each(list[i]);
      if (problem != null) {
        return ApplicationFormStrings.aboutItem(noun, i + 1, problem);
      }
    }
    return null;
  }

  /// The facts, each a row of name, type and value: see
  /// `ApplicationFactValidators`.
  static String? facts(List<Object?>? rows) {
    final seen = <String>{};
    return items(rows, ApplicationFormStrings.factNoun, (row) {
      final map = row is Map ? row : const <Object?, Object?>{};
      final name = map[ApplicationFormFields.nameKey];
      final problem = ApplicationFactValidators.name(name);
      if (problem != null) return problem;
      if (!seen.add(name! as String)) {
        return ApplicationFormStrings.factNameTwice(name as String);
      }
      return ApplicationFactValidators.value(map);
    });
  }

  /// An age category: an English name and, when its age limit is ticked,
  /// at least one birth date, the two in order.
  static String? ageCategory(Object? item) {
    final map = item is Map ? item : const <Object?, Object?>{};
    final label = ApplicationCustomText.fromJson(
      map[ApplicationFormFields.labelKey],
    ).text;
    if ((label[ApplicationFormFields.english] ?? '').isEmpty) {
      return ApplicationFormStrings.nameEnglishRequired;
    }
    final after = map[ApplicationFormFields.bornOnOrAfterKey];
    final before = map[ApplicationFormFields.bornOnOrBeforeKey];
    if (map[ApplicationFormFields.ageLimitKey] == true &&
        after is! String &&
        before is! String) {
      return ApplicationFormStrings.birthDateRequired;
    }
    if (after is String && before is String && before.compareTo(after) < 0) {
      return ApplicationFormStrings.birthOrder;
    }
    return null;
  }

  /// A term: a clause of kind rule, or a custom heading and text, both
  /// with English.
  static String? term(Object? item, ApplicationTextSources sources) {
    final map = item is Map ? item : const <Object?, Object?>{};
    if (map.containsKey(ApplicationTextValue.clauseKey)) {
      return text(
        map,
        sources,
        required: true,
        kind: ApplicationClauseKind.rule,
      );
    }
    return part(
          ApplicationFormStrings.heading,
          text(map[ApplicationFormFields.headingKey], sources, required: true),
        ) ??
        part(
          ApplicationFormStrings.text,
          text(map[ApplicationFormFields.bodyKey], sources, required: true),
        );
  }

  /// A note under the terms: its text, a note clause or custom; and its
  /// attribution, optional, custom.
  static String? note(Object? item, ApplicationTextSources sources) {
    final map = item is Map ? item : const <Object?, Object?>{};
    return text(
          map[ApplicationFormFields.textKey],
          sources,
          required: true,
          kind: ApplicationClauseKind.note,
        ) ??
        part(
          ApplicationFormStrings.attribution,
          text(map[ApplicationFormFields.attributionKey], sources),
        );
  }

  /// [problem] about the part labelled [label]; null when there is none.
  static String? part(String label, String? problem) =>
      problem == null ? null : ApplicationFormStrings.aboutPart(label, problem);

  /// An English text typed in a plain input: the title of a new
  /// application.
  static String? englishText(String? value) => (value ?? '').trim().isEmpty
      ? ApplicationFormStrings.englishRequired
      : null;

  /// A standard label's text in one language.
  static String? label(String? value) => (value ?? '').trim().isEmpty
      ? ApplicationFormStrings.labelRequired
      : null;
}
