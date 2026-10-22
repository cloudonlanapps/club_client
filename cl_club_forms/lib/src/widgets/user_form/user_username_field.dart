import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_autofocus.dart';
import '../form/labeled_form_row.dart';
import 'user_form_fields.dart';
import 'user_form_strings.dart';
import 'user_form_validators.dart';

/// The username of a new account, shared by the forms that create one.
///
/// A plain input with its format rule ([UserFormValidators.username]); a
/// username the server finds taken is refused on save and put back on this
/// field by the host (`showErrors`), like any other refused field.
class UserUsernameField extends StatelessWidget {
  const UserUsernameField({this.enabled = true, super.key});

  /// The characters a username may hold, filtered as they are typed.
  static final RegExp allowedCharacters = RegExp('[a-z0-9_]');

  /// Whether the field responds.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return LabeledFormRow(
      label: UserFormStrings.username,
      required: true,
      field: ShadInputFormField(
        id: UserFormFields.usernameId,
        placeholder: const Text(UserFormStrings.usernamePlaceholder),
        description: const Text(UserFormStrings.usernameHint),
        autofocus: FormAutofocus.allowed,
        keyboardType: TextInputType.text,
        autocorrect: false,
        enableSuggestions: false,
        textInputAction: TextInputAction.next,
        enabled: enabled,
        inputFormatters: [
          FilteringTextInputFormatter.allow(allowedCharacters),
        ],
        validator: UserFormValidators.username,
      ),
    );
  }
}
