import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/labeled_form_row.dart';
import 'user_form_fields.dart';
import 'user_form_strings.dart';
import 'user_form_validators.dart';

/// Email and phone, shared by the user forms. Sits inside the embedding
/// form's `ShadForm`, which holds the initial values.
class UserContactFields extends StatelessWidget {
  const UserContactFields({
    this.enabled = true,
    this.emailFirst = true,
    super.key,
  });

  /// Whether the fields respond.
  final bool enabled;

  /// Whether the email comes before the phone; the forms that create an
  /// account ask for the phone first.
  final bool emailFirst;

  @override
  Widget build(BuildContext context) {
    final email = LabeledFormRow(
      label: UserFormStrings.email,
      required: true,
      field: ShadInputFormField(
        id: UserFormFields.emailId,
        placeholder: const Text(UserFormStrings.emailPlaceholder),
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
        enableSuggestions: false,
        textInputAction: emailFirst
            ? TextInputAction.next
            : TextInputAction.done,
        enabled: enabled,
        validator: UserFormValidators.email,
      ),
    );
    final phone = LabeledFormRow(
      label: UserFormStrings.phone,
      required: true,
      field: ShadInputFormField(
        id: UserFormFields.phoneId,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        enabled: enabled,
        validator: UserFormValidators.phone,
      ),
    );
    return FormBody(children: emailFirst ? [email, phone] : [phone, email]);
  }
}
