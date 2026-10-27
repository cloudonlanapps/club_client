import 'dart:convert';

import 'package:cl_club_forms/cl_club_forms.dart' show ApplicationFormFields;
import 'package:club_sdk_2/club_sdk_2.dart';

/// Translates an application template between the SDK's
/// [ApplicationContent] and the JSON the `cl_club_forms` application forms
/// speak (form rule 7).
///
/// The two hold the same content under different names: the forms use the
/// template's snake_case keys (`form_footer`, `age_categories`,
/// `terms_notes`, `label_overrides`) and give a day as `YYYY-MM-DD`
/// (a fact's date, a range's ends, an age category's birth dates); the SDK
/// uses camelCase keys and a day as UTC-midnight milliseconds. Everything
/// else — the texts, header items, terms, facts' other values — has the
/// same shape on both sides.
abstract final class ApplicationFormJson {
  /// The key of a day-valued fact's value.
  static const String valueKey = ApplicationFormFields.valueKey;

  /// [content] as the forms hold it.
  static Map<String, dynamic> fromContent(ApplicationContent content) => {
    ApplicationFormFields.languagesId: [...content.languages],
    ApplicationFormFields.factsId: {
      for (final e in content.facts.entries) e.key: factToForm(e.value),
    },
    ApplicationFormFields.organisationId: content.organisation?.toMap(),
    ApplicationFormFields.titleId: content.title?.toMap(),
    ApplicationFormFields.subtitleId: content.subtitle?.toMap(),
    ApplicationFormFields.formFooterId: content.formFooter?.toMap(),
    ApplicationFormFields.headerId: [
      for (final h in content.header) h.toWire(),
    ],
    ApplicationFormFields.ageCategoriesId: [
      for (final c in content.ageCategories) categoryToForm(c),
    ],
    ApplicationFormFields.selectionsId: [
      for (final s in content.selections) s.toMap(),
    ],
    ApplicationFormFields.declarationId: content.declaration?.toMap(),
    ApplicationFormFields.termsId: [for (final t in content.terms) t.toMap()],
    ApplicationFormFields.termsNotesId: [
      for (final n in content.termsNotes) n.toMap(),
    ],
    ApplicationFormFields.labelOverridesId: {
      for (final e in content.labelOverrides.entries) e.key: {...e.value},
    },
  };

  /// The forms' [json], a whole template, as the SDK's content; a key it
  /// lacks takes the SDK's default.
  static ApplicationContent toContent(Map<String, dynamic> json) {
    final j = plain(json);
    return ApplicationContent(
      languages: languages(j[ApplicationFormFields.languagesId]),
      facts: facts(j[ApplicationFormFields.factsId]),
      organisation: text(j[ApplicationFormFields.organisationId]),
      title: text(j[ApplicationFormFields.titleId]),
      subtitle: text(j[ApplicationFormFields.subtitleId]),
      header: header(j[ApplicationFormFields.headerId]),
      ageCategories: ageCategories(j[ApplicationFormFields.ageCategoriesId]),
      selections: selections(j[ApplicationFormFields.selectionsId]),
      declaration: text(j[ApplicationFormFields.declarationId]),
      formFooter: text(j[ApplicationFormFields.formFooterId]),
      terms: terms(j[ApplicationFormFields.termsId]),
      termsNotes: notes(j[ApplicationFormFields.termsNotesId]),
      labelOverrides: labelOverrides(j[ApplicationFormFields.labelOverridesId]),
    );
  }

  /// [json] with every map a `Map<String, dynamic>` and every list a
  /// `List<dynamic>`, as the SDK's readers take them.
  static Map<String, dynamic> plain(Map<String, dynamic> json) =>
      jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

  /// A day as the forms give it, `YYYY-MM-DD`, as its UTC midnight; null
  /// for anything else.
  static DateTime? dayFromForm(Object? day) {
    if (day is! String) return null;
    final parts = day.split('-');
    if (parts.length != 3) return null;
    final [y, m, d] = [for (final p in parts) int.tryParse(p)];
    if (y == null || m == null || d == null) return null;
    return DateTime.utc(y, m, d);
  }

  /// [dateUtc]'s day as the forms give it, `YYYY-MM-DD`.
  static String dayToForm(DateTime dateUtc) =>
      '${dateUtc.year.toString().padLeft(4, '0')}-'
      '${dateUtc.month.toString().padLeft(2, '0')}-'
      '${dateUtc.day.toString().padLeft(2, '0')}';

  /// [fact] as the forms hold it.
  static Map<String, Object?> factToForm(ApplicationFact fact) {
    final type = fact.type.wireName;
    return switch (fact.type) {
      ApplicationFactType.date => {
        ApplicationFormFields.typeKey: type,
        valueKey: fact.dateUtc == null ? null : dayToForm(fact.dateUtc!),
      },
      ApplicationFactType.dateRange => {
        ApplicationFormFields.typeKey: type,
        ApplicationFormFields.fromKey: fact.fromUtc == null
            ? null
            : dayToForm(fact.fromUtc!),
        ApplicationFormFields.toKey: fact.toUtc == null
            ? null
            : dayToForm(fact.toUtc!),
      },
      ApplicationFactType.time => {
        ApplicationFormFields.typeKey: type,
        valueKey: timeToForm(fact.time),
      },
      _ => {ApplicationFormFields.typeKey: type, valueKey: fact.value},
    };
  }

  /// A time as the forms give it, `HH:MM`: the server also takes `H:MM`.
  static String? timeToForm(String? time) {
    if (time == null) return null;
    final [hour, ...rest] = time.split(':');
    return [hour.padLeft(2, '0'), ...rest].join(':');
  }

  /// [category] as the forms hold it.
  static Map<String, Object?> categoryToForm(ApplicationAgeCategory category) {
    final after = category.bornOnOrAfterUtc;
    final before = category.bornOnOrBeforeUtc;
    return {
      ApplicationFormFields.labelKey: {...category.label},
      if (after != null)
        ApplicationFormFields.bornOnOrAfterKey: dayToForm(after),
      if (before != null)
        ApplicationFormFields.bornOnOrBeforeKey: dayToForm(before),
      if (category.genders case final genders?)
        ApplicationFormFields.gendersKey: [
          for (final g in genders) g.serverValue,
        ],
    };
  }

  /// The print languages in [json]; English alone for none.
  static List<String> languages(Object? json) {
    final codes = [if (json is List) ...json.whereType<String>()];
    return codes.isEmpty ? const [ApplicationFormFields.english] : codes;
  }

  /// A printed text, or null for none.
  static ApplicationText? text(Object? json) => ApplicationText.fromWire(json);

  /// The facts of [json], by name; a note (`_…`) or a fact of no known type
  /// is left out.
  static Map<String, ApplicationFact> facts(Object? json) => {
    if (json is Map<String, dynamic>)
      for (final e in json.entries)
        if (!e.key.startsWith('_'))
          if (factFromForm(e.value) case final ApplicationFact fact)
            e.key: fact,
  };

  /// One fact as the forms hold it, as the SDK's; null when its type is
  /// none the SDK knows.
  static ApplicationFact? factFromForm(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final ApplicationFactType type;
    try {
      type = ApplicationFactType.fromWire(
        json[ApplicationFormFields.typeKey] as String? ?? '',
      );
    } on FormatException {
      return null;
    }
    final value = json[valueKey];
    return switch (type) {
      ApplicationFactType.date => ApplicationFact(
        type: type,
        value: dayFromForm(value)?.millisecondsSinceEpoch,
      ),
      ApplicationFactType.dateRange => ApplicationFact(
        type: type,
        fromUtc: dayFromForm(json[ApplicationFormFields.fromKey]),
        toUtc: dayFromForm(json[ApplicationFormFields.toKey]),
      ),
      ApplicationFactType.name => ApplicationFact(
        type: type,
        value: value is Map ? ApplicationText.stringMap(value) : value,
      ),
      ApplicationFactType.choices => ApplicationFact(
        type: type,
        value: [if (value is List) ...value.whereType<String>()],
      ),
      _ => ApplicationFact(type: type, value: value),
    };
  }

  /// The header items of [json].
  static List<ApplicationHeaderItem> header(Object? json) => [
    if (json is List)
      for (final item in json)
        if (item is Map || item is List)
          ApplicationHeaderItem.fromWire(item as Object),
  ];

  /// The age categories of [json].
  static List<ApplicationAgeCategory> ageCategories(Object? json) => [
    if (json is List)
      for (final c in json.whereType<Map<String, dynamic>>())
        ApplicationAgeCategory(
          label: ApplicationText.stringMap(
            c[ApplicationFormFields.labelKey] as Map? ?? const {},
          ),
          bornOnOrAfterUtc: dayFromForm(
            c[ApplicationFormFields.bornOnOrAfterKey],
          ),
          bornOnOrBeforeUtc: dayFromForm(
            c[ApplicationFormFields.bornOnOrBeforeKey],
          ),
          genders: switch (c[ApplicationFormFields.gendersKey]) {
            final List<dynamic> g when g.isNotEmpty => [
              for (final name in g.whereType<String>()) Gender.fromName(name),
            ],
            _ => null,
          },
        ),
  ];

  /// The additional selections of [json].
  static List<ApplicationText> selections(Object? json) => [
    if (json is List)
      for (final s in json.whereType<Map<String, dynamic>>())
        ApplicationText.fromMap(s),
  ];

  /// The terms of [json].
  static List<ApplicationTerm> terms(Object? json) => [
    if (json is List)
      for (final t in json.whereType<Map<String, dynamic>>())
        ApplicationTerm.fromMap(t),
  ];

  /// The notes of [json].
  static List<ApplicationTermsNote> notes(Object? json) => [
    if (json is List)
      for (final n in json.whereType<Map<String, dynamic>>()) noteFromForm(n),
  ];

  /// One note as the forms hold it, as the SDK's: its text, and an
  /// attribution when it has one. A note that is a bare text, not under
  /// `text`, is that text.
  static ApplicationTermsNote noteFromForm(Map<String, dynamic> note) {
    final body = note[ApplicationFormFields.textKey];
    return ApplicationTermsNote(
      text: text(body is Map ? body : note) ?? const ApplicationText({}),
      attribution: text(note[ApplicationFormFields.attributionKey]),
    );
  }

  /// The label overrides of [json], by label id.
  static Map<String, Map<String, String>> labelOverrides(Object? json) => {
    if (json is Map<String, dynamic>)
      for (final e in json.entries)
        if (e.value is Map) e.key: ApplicationText.stringMap(e.value as Map),
  };
}
