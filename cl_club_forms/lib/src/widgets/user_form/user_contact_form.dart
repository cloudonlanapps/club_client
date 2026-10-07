import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/form_contract.dart';
import 'user_contact_fields.dart';
import 'user_emergency_fields.dart';
import 'user_field_pair.dart';
import 'user_form_assembly.dart';
import 'user_form_fields.dart';

/// Pure-UI editor for a user's contact info — email, phone, emergency
/// contact and medical notes (the "Contact" profile section).
///
/// The form owns no title or buttons: the host drives it through a
/// `GlobalKey<UserContactFormState>` — `validate()` from its Save action,
/// `showErrors()` when the server refuses a value ([FormContract]).
class UserContactForm extends StatefulWidget {
  const UserContactForm({
    required this.initialValues,
    this.enabled = true,
    super.key,
  });

  /// Initial values; reads the ids of [UserFormFields.contactIds].
  final Map<String, dynamic> initialValues;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  @override
  State<UserContactForm> createState() => UserContactFormState();
}

/// State of [UserContactForm]. Its values are the fields of
/// [UserFormFields.contactIds], for a partial update.
class UserContactFormState extends State<UserContactForm>
    with FormContract<UserContactForm> {
  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) =>
      UserFormAssembly.pick(UserFormFields.contactIds, values);

  @override
  Widget build(BuildContext context) {
    return ShadForm(
      key: formKey,
      initialValue: UserFormAssembly.seed(
        UserFormFields.contactIds,
        widget.initialValues,
      ),
      child: FormBody(
        error: formError,
        children: [
          UserContactFields(enabled: widget.enabled),
          UserEmergencyFields(
            enabled: widget.enabled,
            pairMinWidth: UserFieldPair.never,
          ),
        ],
      ),
    );
  }
}
