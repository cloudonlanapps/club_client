import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/labeled_form_row.dart';
import 'user_form_fields.dart';
import 'user_form_strings.dart';
import 'user_optional_choice_field.dart';

/// The background of the extended profile: nationality and preferred
/// language. Sits inside the embedding form's `ShadForm`, which holds the
/// initial values.
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
          label: UserFormStrings.preferredLanguage,
          field: UserOptionalChoiceField(
            id: UserFormFields.preferredLanguagesId,
            enabled: enabled,
            options: {for (final language in languages) language: language},
          ),
        ),
      ],
    );
  }
}
