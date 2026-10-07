import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/labeled_form_row.dart';
import 'user_field_pair.dart';
import 'user_form_fields.dart';
import 'user_form_strings.dart';

/// The name fields the user forms share: first, middle and last name and,
/// with [showNickname], the nickname. Sits inside the embedding form's
/// `ShadForm`, which holds the initial values.
///
/// First and last name carry the required mark: the embedding form refuses
/// a user with neither (`UserFormValidators.atLeastOneName`).
class UserNameFields extends StatelessWidget {
  const UserNameFields({
    this.enabled = true,
    this.showNickname = false,
    this.autofocus = false,
    this.pairMinWidth = UserFieldPair.sideBySideMinWidth,
    super.key,
  });

  /// Whether the fields respond.
  final bool enabled;

  /// Whether the nickname is edited too.
  final bool showNickname;

  /// Whether the first name takes the focus when the form opens.
  final bool autofocus;

  /// Width from which first and middle name sit side by side.
  final double pairMinWidth;

  @override
  Widget build(BuildContext context) {
    return FormBody(
      children: [
        UserFieldPair(
          minWidth: pairMinWidth,
          first: LabeledFormRow(
            label: UserFormStrings.firstName,
            required: true,
            field: ShadInputFormField(
              id: UserFormFields.firstNameId,
              autofocus: autofocus,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              enabled: enabled,
            ),
          ),
          second: LabeledFormRow(
            label: UserFormStrings.middleName,
            field: ShadInputFormField(
              id: UserFormFields.middleNameId,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              enabled: enabled,
            ),
          ),
        ),
        LabeledFormRow(
          label: UserFormStrings.lastName,
          required: true,
          field: ShadInputFormField(
            id: UserFormFields.lastNameId,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            enabled: enabled,
          ),
        ),
        if (showNickname)
          LabeledFormRow(
            label: UserFormStrings.nickname,
            field: ShadInputFormField(
              id: UserFormFields.nicknameId,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              enabled: enabled,
            ),
          ),
      ],
    );
  }
}
