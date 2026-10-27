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

  /// A language as held: its code and name.
  static Map<String, String> language(Object? raw) => {
    ProfileOptionsFormFields.codeKey: raw is Map
        ? text(raw[ProfileOptionsFormFields.codeKey])
        : '',
    ProfileOptionsFormFields.nameKey: raw is Map
        ? text(raw[ProfileOptionsFormFields.nameKey])
        : '',
  };

  /// The languages of [raw], a list of `{code, name}` maps, as held:
  /// English first, added when [raw] lacks it (club_client#396).
  static List<Map<String, String>> languages(Object? raw) {
    const english = ProfileOptionsFormFields.requiredLabelLanguage;
    final all = [
      if (raw is List)
        for (final item in raw) language(item),
    ];
    bool isEnglish(Map<String, String> l) =>
        l[ProfileOptionsFormFields.codeKey]!.trim() == english;
    return [
      all.firstWhere(
        isEnglish,
        orElse: () => {
          ProfileOptionsFormFields.codeKey: english,
          ProfileOptionsFormFields.nameKey:
              ProfileOptionsFormFields.englishName,
        },
      ),
      for (final l in all)
        if (!isEnglish(l)) l,
    ];
  }

  /// The languages [raw] holds that a position gets a label in: each with
  /// a code, in order, once (club_client#396).
  static List<ProfileLabelLanguage> labelLanguages(Object? raw) {
    final seen = <String>{};
    return [
      for (final l in languagesOut(raw))
        if (l[ProfileOptionsFormFields.codeKey]!.isNotEmpty &&
            seen.add(l[ProfileOptionsFormFields.codeKey]!))
          ProfileLabelLanguage(
            code: l[ProfileOptionsFormFields.codeKey]!,
            name: l[ProfileOptionsFormFields.nameKey]!.isEmpty
                ? l[ProfileOptionsFormFields.codeKey]!
                : l[ProfileOptionsFormFields.nameKey]!,
          ),
    ];
  }

  /// The value of the position [raw] holds, trimmed.
  static String valueOf(Object? raw) =>
      raw is Map ? text(raw[ProfileOptionsFormFields.valueKey]).trim() : '';

  /// The label of the position [raw] holds in [code], trimmed.
  static String labelOf(Object? raw, String code) {
    final labels = raw is Map ? raw[ProfileOptionsFormFields.labelKey] : null;
    return labels is Map ? text(labels[code]).trim() : '';
  }

  /// The positions as returned: value and labels trimmed, empty labels
  /// and labels in a language not among [codes] left out (the server
  /// refuses a label in a language the club lacks).
  static List<Map<String, Object>> positionsOut(
    Object? raw,
    Iterable<String> codes,
  ) {
    final keep = codes.toSet();
    return [
      if (raw is List)
        for (final item in raw)
          {
            ProfileOptionsFormFields.valueKey: valueOf(item),
            ProfileOptionsFormFields.labelKey: <String, String>{
              for (final code in labelCodes(item))
                if (keep.contains(code) && labelOf(item, code).isNotEmpty)
                  code: labelOf(item, code),
            },
          },
    ];
  }

  /// The language codes the position [raw] has a label entry for.
  static List<String> labelCodes(Object? raw) {
    final labels = raw is Map ? raw[ProfileOptionsFormFields.labelKey] : null;
    return labels is Map ? labels.keys.whereType<String>().toList() : const [];
  }

  /// The languages as returned: codes and names trimmed, English first.
  static List<Map<String, String>> languagesOut(Object? raw) => [
    for (final l in languages(raw))
      {
        ProfileOptionsFormFields.codeKey: l[ProfileOptionsFormFields.codeKey]!
            .trim(),
        ProfileOptionsFormFields.nameKey: l[ProfileOptionsFormFields.nameKey]!
            .trim(),
      },
  ];
}
