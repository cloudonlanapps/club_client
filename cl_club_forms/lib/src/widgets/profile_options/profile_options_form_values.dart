import '../../models/profile_label_language.dart';
import 'profile_options_form_fields.dart';

/// Reads and shapes the values of `ProfileOptionsForm`: what the host
/// passes in becomes the rows its editors hold, and the rows become what
/// `validate()` returns.
abstract final class ProfileOptionsFormValues {
  /// The text of [raw], or `''` when it holds none.
  static String text(Object? raw) => raw is String ? raw : '';

  /// The labels of a position as held: a text for each of
  /// [labelLanguages], `''` when it has none, and every other label it
  /// has kept as it is.
  static Map<String, String> labels(
    Object? raw,
    List<ProfileLabelLanguage> labelLanguages,
  ) => {
    if (raw is Map)
      for (final entry in raw.entries)
        if (entry.key is String) entry.key as String: text(entry.value),
    for (final language in labelLanguages)
      language.code: raw is Map ? text(raw[language.code]) : '',
  };

  /// A position as held: its value and its [labels].
  static Map<String, Object?> position(
    Object? raw,
    List<ProfileLabelLanguage> labelLanguages,
  ) => {
    ProfileOptionsFormFields.valueKey: raw is Map
        ? text(raw[ProfileOptionsFormFields.valueKey])
        : '',
    ProfileOptionsFormFields.labelKey: labels(
      raw is Map ? raw[ProfileOptionsFormFields.labelKey] : null,
      labelLanguages,
    ),
  };

  /// The positions of [raw], a list of maps, as held.
  static List<Map<String, Object?>> positions(
    Object? raw,
    List<ProfileLabelLanguage> labelLanguages,
  ) => [
    if (raw is List)
      for (final item in raw) position(item, labelLanguages),
  ];

  /// The languages of [raw], a list of names, as held.
  static List<String> languages(Object? raw) => [
    if (raw is List)
      for (final item in raw) text(item),
  ];

  /// The value of the position [raw] holds, trimmed.
  static String valueOf(Object? raw) =>
      raw is Map ? text(raw[ProfileOptionsFormFields.valueKey]).trim() : '';

  /// The label of the position [raw] holds in [code], trimmed.
  static String labelOf(Object? raw, String code) {
    final labels = raw is Map ? raw[ProfileOptionsFormFields.labelKey] : null;
    return labels is Map ? text(labels[code]).trim() : '';
  }

  /// The positions as returned: value and labels trimmed, empty labels
  /// left out.
  static List<Map<String, Object>> positionsOut(Object? raw) => [
    if (raw is List)
      for (final item in raw)
        {
          ProfileOptionsFormFields.valueKey: valueOf(item),
          ProfileOptionsFormFields.labelKey: <String, String>{
            for (final code in labelCodes(item))
              if (labelOf(item, code).isNotEmpty) code: labelOf(item, code),
          },
        },
  ];

  /// The language codes the position [raw] has a label entry for.
  static List<String> labelCodes(Object? raw) {
    final labels = raw is Map ? raw[ProfileOptionsFormFields.labelKey] : null;
    return labels is Map ? labels.keys.whereType<String>().toList() : const [];
  }

  /// The languages as returned: names trimmed.
  static List<String> languagesOut(Object? raw) => [
    for (final name in languages(raw)) name.trim(),
  ];
}
