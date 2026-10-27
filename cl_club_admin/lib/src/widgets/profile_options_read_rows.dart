import 'package:club_sdk_2/club_sdk_2.dart' show ProfileOptions;
import 'package:flutter/widgets.dart';

import '../constants/profile_options_messages.dart';
import 'labeled_value.dart';

/// The club's profile options as the Profile options section reads them:
/// each position with its labels, and the languages.
class ProfileOptionsReadRows extends StatelessWidget {
  const ProfileOptionsReadRows({required this.options, super.key});

  /// Gap between the two rows.
  static const double rowGap = 12;

  /// The options the server holds.
  final ProfileOptions options;

  /// How [options]' positions read: each by its labels, in the order of
  /// the club's languages, or its value when it has none.
  String get positionsText {
    if (options.positions.isEmpty) return ProfileOptionsMessages.none;
    return [
      for (final position in options.positions)
        if ([
              for (final code in options.codes) ?position.label[code],
            ].join(ProfileOptionsMessages.labelSeparator)
            case final labels when labels.isNotEmpty)
          labels
        else
          position.value,
    ].join(ProfileOptionsMessages.listSeparator);
  }

  @override
  Widget build(BuildContext context) {
    final languages = options.languages;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: rowGap,
      children: [
        LabeledValue(
          label: ProfileOptionsMessages.positions,
          value: positionsText,
        ),
        LabeledValue(
          label: ProfileOptionsMessages.languages,
          value: languages.isEmpty
              ? ProfileOptionsMessages.none
              : [
                  for (final language in languages) language.name,
                ].join(ProfileOptionsMessages.listSeparator),
        ),
      ],
    );
  }
}
