import 'event_marketing_form_validators.dart';

/// [rows] as marketing rows: each a `Map<String, Object?>`, whatever list
/// type held them (a form keeps its values as plain lists).
List<Map<String, Object?>> asMarketingRows(Object? rows) => [
  for (final row in (rows as List<Object?>?) ?? const <Object?>[])
    Map<String, Object?>.from(row! as Map),
];

/// [rows] without the blank ones, each text trimmed: what a marketing form
/// returns for a list.
List<Map<String, Object?>> marketingRows(Object? rows) => [
  for (final row in asMarketingRows(rows))
    if (!EventMarketingFormValidators.isBlankRow(row))
      {
        for (final entry in row.entries)
          entry.key: entry.value is String
              ? (entry.value! as String).trim()
              : entry.value,
      },
];

/// [rows] as initial values of a list field: a copy of each row.
List<Map<String, Object?>> marketingInitialRows(Object? rows) =>
    asMarketingRows(rows);
