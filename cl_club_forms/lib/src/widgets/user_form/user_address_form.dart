import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/form_contract.dart';
import 'user_address_fields.dart';
import 'user_field_pair.dart';
import 'user_form_assembly.dart';
import 'user_form_fields.dart';

/// Pure-UI editor for a user's postal address — the "Address" profile
/// section.
///
/// The form owns no title or buttons: the host drives it through a
/// `GlobalKey<UserAddressFormState>` ([FormContract]).
class UserAddressForm extends StatefulWidget {
  const UserAddressForm({
    required this.initialValues,
    this.enabled = true,
    super.key,
  });

  /// Initial values; reads the ids of [UserFormFields.addressIds].
  final Map<String, dynamic> initialValues;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  @override
  State<UserAddressForm> createState() => UserAddressFormState();
}

/// State of [UserAddressForm]. Its values are the fields of
/// [UserFormFields.addressIds], for a partial update.
class UserAddressFormState extends State<UserAddressForm>
    with FormContract<UserAddressForm> {
  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) =>
      UserFormAssembly.pick(UserFormFields.addressIds, values);

  @override
  Widget build(BuildContext context) {
    return ShadForm(
      key: formKey,
      initialValue: UserFormAssembly.seed(
        UserFormFields.addressIds,
        widget.initialValues,
      ),
      child: FormBody(
        error: formError,
        children: [
          UserAddressFields(
            enabled: widget.enabled,
            pairMinWidth: UserFieldPair.never,
          ),
        ],
      ),
    );
  }
}
