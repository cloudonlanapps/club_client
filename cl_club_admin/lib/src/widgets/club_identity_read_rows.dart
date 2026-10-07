import 'package:cl_club_forms/cl_club_forms.dart' show FormTranslatedText;
import 'package:flutter/widgets.dart';
import 'package:ui_lib/ui_lib.dart' show DetailRow;

/// The read view of one club details section: a row per value that is set,
/// in the order of [labels]. A translatable value shows its default text
/// and then a row per translation, labelled with the language.
class ClubIdentityReadRows extends StatelessWidget {
  const ClubIdentityReadRows({
    required this.values,
    required this.labels,
    required this.icons,
    super.key,
  });

  /// The section's values as its form takes them, keyed by field id: a
  /// `String`, or a [FormTranslatedText] for a translatable field.
  final Map<String, dynamic> values;

  /// The label of each field of the section, in display order.
  final Map<String, String> labels;

  /// The icon of each field of the section.
  final Map<String, IconData> icons;

  /// Whether none of the fields [ids] holds a value in [values].
  static bool isEmptyOf(Map<String, dynamic> values, Iterable<String> ids) =>
      ids.every(
        (id) => switch (values[id]) {
          final String text => text.isEmpty,
          final FormTranslatedText text => text.isEmpty,
          _ => true,
        },
      );

  /// The label of [label]'s translation in [language].
  static String translationLabel(String label, String language) =>
      '$label ($language)';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final MapEntry(key: id, value: label) in labels.entries)
          ...switch (values[id]) {
            final String text when text.isNotEmpty => [
              DetailRow(icon: icons[id]!, label: label, value: text),
            ],
            final FormTranslatedText text => [
              if (text.defaultValue.isNotEmpty)
                DetailRow(
                  icon: icons[id]!,
                  label: label,
                  value: text.defaultValue,
                ),
              for (final translation in text.byLanguage.entries)
                DetailRow(
                  icon: icons[id]!,
                  label: translationLabel(label, translation.key),
                  value: translation.value,
                ),
            ],
            _ => const <Widget>[],
          },
      ],
    );
  }
}
