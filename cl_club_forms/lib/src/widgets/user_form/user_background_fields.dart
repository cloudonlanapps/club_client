import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/labeled_form_row.dart';
import 'user_choices_field.dart';
import 'user_form_fields.dart';
import 'user_form_strings.dart';

/// The background of the extended profile: nationality and preferred
/// languages (any number of the club's). Sits inside the embedding form's
/// `ShadForm`, which holds the initial values.
class UserBackgroundFields extends StatelessWidget {
  const UserBackgroundFields({
    required this.languages,
    this.enabled = true,
    super.key,
  });

  /// The club's languages, by name, in order.
  final List<String> languages;

  /// Whether the fields respond.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FormBody(
      children: [
        LabeledFormRow(
          label: UserFormStrings.nationality,
          field: ShadInputFormField(
            id: UserFormFields.nationalityId,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            enabled: enabled,
          ),
        ),
        LabeledFormRow(
          label: UserFormStrings.preferredLanguages,
          field: UserChoicesField(
            id: UserFormFields.preferredLanguagesId,
            enabled: enabled,
            noneTickedHint: UserFormStrings.noLanguageChosen,
            options: {for (final language in languages) language: language},
          ),
        ),
      ],
    );
  }
}
