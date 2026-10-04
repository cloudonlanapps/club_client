import 'package:club_sdk_2/club_sdk_2.dart';

/// The icon a club value gets when the server names none.
const String defaultClubValueIconName = 'heart';

/// The server's untyped `clubInfo` key holding the club's history.
const String clubInfoHistoryKey = 'history';

/// The key under [clubInfoHistoryKey] holding its paragraphs.
const String clubInfoParagraphsKey = 'paragraphs';

/// The server's untyped `clubInfo` key holding the club's values.
const String clubInfoValuesKey = 'values';

/// A club value's title key; a value without one is skipped.
const String clubValueTitleKey = 'title';

/// A club value's icon key.
const String clubValueIconKey = 'iconName';

/// A club value's description key.
const String clubValueDescriptionKey = 'description';

/// Reads the club's history and values out of the server's untyped
/// `clubInfo` (club_core#53), part by part over [fallback].
///
/// Every field is checked rather than cast. A part that is present but
/// unusable falls back whole: history and values are one piece of writing
/// each, and half of one from each source would read as neither.
ClubInfo clubContentFromServer(
  Map<String, dynamic> clubInfo, {
  required ClubInfo fallback,
}) {
  final history = clubInfo[clubInfoHistoryKey];
  final rawParagraphs = history is Map ? history[clubInfoParagraphsKey] : null;
  final paragraphs = rawParagraphs is List
      ? [
          for (final item in rawParagraphs)
            if (item is String && item.isNotEmpty) item,
        ]
      : const <String>[];

  final rawValues = clubInfo[clubInfoValuesKey];
  final values = rawValues is List
      ? [
          for (final item in rawValues)
            if (item is Map && item[clubValueTitleKey] is String)
              ClubValueCardData(
                iconName: item[clubValueIconKey] is String
                    ? item[clubValueIconKey] as String
                    : defaultClubValueIconName,
                title: item[clubValueTitleKey] as String,
                description: item[clubValueDescriptionKey] is String
                    ? item[clubValueDescriptionKey] as String
                    : '',
              ),
        ]
      : const <ClubValueCardData>[];

  return ClubInfo(
    history: paragraphs.isEmpty
        ? fallback.history
        : ClubHistoryData(paragraphs: paragraphs),
    values: values.isEmpty ? fallback.values : values,
  );
}
