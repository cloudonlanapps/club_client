import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/form_contract.dart';
import 'user_background_fields.dart';
import 'user_form_assembly.dart';
import 'user_form_fields.dart';

/// Pure-UI editor for a member's background — nationality and preferred
/// language (the "Background" section of the extended profile). Both may
/// be left blank.
///
/// The form owns no title or buttons: the host drives it through a
/// `GlobalKey<UserBackgroundFormState>` ([FormContract]).
class UserBackgroundForm extends StatefulWidget {
  const UserBackgroundForm({
    required this.initialValues,
    required this.languages,
    this.enabled = true,
    super.key,
  });

  /// Initial values; reads the ids of [UserFormFields.backgroundIds].
  final Map<String, dynamic> initialValues;

  /// The club's languages, by name, offered by the preferred-language
  /// select. A member's language that is not among them shows and is kept.
  final List<String> languages;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  @override
  State<UserBackgroundForm> createState() => UserBackgroundFormState();
}

/// State of [UserBackgroundForm]. Its values are the fields of
/// [UserFormFields.backgroundIds], each a `String` (`''` when blank), for a
/// partial update.
class UserBackgroundFormState extends State<UserBackgroundForm>
    with FormContract<UserBackgroundForm> {
  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) =>
      UserFormAssembly.pick(UserFormFields.backgroundIds, values);

  @override
  Widget build(BuildContext context) {
    return ShadForm(
      key: formKey,
      initialValue: UserFormAssembly.seed(
        UserFormFields.backgroundIds,
        widget.initialValues,
      ),
      child: FormBody(
        error: formError,
        children: [
          UserBackgroundFields(
            languages: widget.languages,
            enabled: widget.enabled,
          ),
        ],
      ),
    );
  }
}
