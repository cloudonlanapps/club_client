import 'package:cl_club_forms/cl_club_forms.dart'
    show ApplicationFactType, ApplicationFormFields;

import '../constants/application_view_strings.dart';
import '../models/application_section.dart';
import 'application_text_reader.dart';

/// One line of a section's read mode: what it is, and how it prints.
typedef ApplicationReadLine = ({String label, String value});

/// The read mode of each editor section: its content as it prints, one
/// line per text, fact or item. A section with nothing in it has no lines.
abstract final class ApplicationSectionLines {
  /// The lines of [section] of the template [reader] reads.
  static List<ApplicationReadLine> of(
    ApplicationSection section,
    ApplicationTextReader reader,
  ) {
    final t = reader.template;
    List<Object?> list(String key) => t[key] is List ? t[key] as List : [];
    final lines = switch (section) {
      ApplicationSection.heading => [
        (
          label: ApplicationViewStrings.printLanguages,
          value: reader.options
              .printLanguages(t)
              .map((l) => l.name)
              .join(ApplicationViewStrings.separator),
        ),
        for (final (label, key) in [
          (
            ApplicationViewStrings.organisation,
            ApplicationFormFields.organisationId,
          ),
          (ApplicationViewStrings.title, ApplicationFormFields.titleId),
          (ApplicationViewStrings.subtitle, ApplicationFormFields.subtitleId),
          (
            ApplicationViewStrings.formFooter,
            ApplicationFormFields.formFooterId,
          ),
        ])
          (label: label, value: reader.read(t[key])),
      ],
      ApplicationSection.facts => [
        for (final MapEntry(key: name, value: type)
            in ApplicationFactType.ofFacts(
              t[ApplicationFormFields.factsId],
            ).entries)
          (
            label: name,
            value: [
              reader.factValue(name, ApplicationFormFields.english),
              type.jsonName,
            ].where((s) => s.isNotEmpty).join(ApplicationViewStrings.separator),
          ),
      ],
      ApplicationSection.header => [
        for (final (i, item) in list(ApplicationFormFields.headerId).indexed)
          (
            label: ApplicationViewStrings.headerItem(i + 1),
            value: reader.read(item),
          ),
      ],
      ApplicationSection.ageCategories => [
        for (final c in list(ApplicationFormFields.ageCategoriesId))
          if (c is Map) ageCategory(c, reader),
      ],
      ApplicationSection.selections => [
        for (final (i, s) in list(ApplicationFormFields.selectionsId).indexed)
          (
            label: ApplicationViewStrings.selection(i + 1),
            value: reader.read(s),
          ),
      ],
      ApplicationSection.declaration => [
        (
          label: ApplicationViewStrings.declaration,
          value: reader.read(t[ApplicationFormFields.declarationId]),
        ),
      ],
      ApplicationSection.terms => [
        for (final (i, term) in list(ApplicationFormFields.termsId).indexed)
          if (term is Map) termLine(i, term, reader),
      ],
      ApplicationSection.notes => [
        for (final (i, note) in list(
          ApplicationFormFields.termsNotesId,
        ).indexed)
          (
            label: ApplicationViewStrings.note(i + 1),
            value: noteText(note, reader),
          ),
      ],
      ApplicationSection.labels => [
        if (t[ApplicationFormFields.labelOverridesId]
            case final Map<Object?, Object?> overrides)
          for (final MapEntry(:key, :value) in overrides.entries)
            (label: labelName('$key', reader), value: reader.read(value)),
      ],
    };
    return [
      for (final line in lines)
        if (line.value.isNotEmpty) line,
    ];
  }

  /// An age category's line: its name, and its birth dates and genders.
  static ApplicationReadLine ageCategory(
    Map<Object?, Object?> category,
    ApplicationTextReader reader,
  ) {
    String? day(String key) {
      final shown = ApplicationTextReader.day(category[key]);
      return shown.isEmpty ? null : shown;
    }

    final genders = category[ApplicationFormFields.gendersKey];
    return (
      label: reader.read(category[ApplicationFormFields.labelKey]),
      value: [
        ApplicationViewStrings.bornBetween(
          day(ApplicationFormFields.bornOnOrAfterKey),
          day(ApplicationFormFields.bornOnOrBeforeKey),
        ),
        if (genders is List && genders.isNotEmpty)
          genders
              .map((g) => ApplicationViewStrings.genderNames[g] ?? '$g')
              .join(', '),
      ].join(ApplicationViewStrings.separator),
    );
  }

  /// A term's line: its heading, and its text.
  static ApplicationReadLine termLine(
    int index,
    Map<Object?, Object?> term,
    ApplicationTextReader reader,
  ) {
    final heading = reader.read(term[ApplicationFormFields.headingKey]);
    return (
      label: heading.isEmpty ? ApplicationViewStrings.term(index + 1) : heading,
      value: reader.read(term[ApplicationFormFields.bodyKey]),
    );
  }

  /// A note's text, then who it is from.
  static String noteText(Object? note, ApplicationTextReader reader) {
    final map = note is Map ? note : const <Object?, Object?>{};
    final body = map.containsKey(ApplicationFormFields.textKey)
        ? map[ApplicationFormFields.textKey]
        : note;
    final from = reader.read(map[ApplicationFormFields.attributionKey]);
    return [reader.read(body), from].where((s) => s.isNotEmpty).join(' — ');
  }

  /// The English text of catalogue label [id]; [id] when it has none.
  static String labelName(String id, ApplicationTextReader reader) {
    for (final label in reader.options.labels) {
      if (label.id == id) {
        return label.text[ApplicationFormFields.english] ?? id;
      }
    }
    return id;
  }
}
