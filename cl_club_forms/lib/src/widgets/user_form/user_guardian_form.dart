import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/form_contract.dart';
import 'user_form_assembly.dart';
import 'user_form_fields.dart';
import 'user_form_validators.dart';
import 'user_guardian_fields.dart';

/// Pure-UI editor for a member's guardian — name, relation and phone (the
/// "Guardian" section of the extended profile), kept apart from the
/// emergency contact. All three may be left blank; once a relation or a
/// phone is given, the name is required, as a rule across the fields
/// shown inline ([UserFormValidators.guardianNamed]).
///
/// The form owns no title or buttons: the host drives it through a
/// `GlobalKey<UserGuardianFormState>` ([FormContract]).
class UserGuardianForm extends StatefulWidget {
  const UserGuardianForm({
    required this.initialValues,
    required this.defaultCountryCode,
    this.enabled = true,
    super.key,
  });

  /// Initial values; reads the ids of [UserFormFields.guardianIds].
  final Map<String, dynamic> initialValues;

  /// The club's country calling code (digits only, as the server reports
  /// it: `91`); the guardian's phone typed without a country code is
  /// checked as a number of that country.
  final String defaultCountryCode;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  @override
  State<UserGuardianForm> createState() => UserGuardianFormState();
}

/// State of [UserGuardianForm]. Its values are the fields of
/// [UserFormFields.guardianIds], each a `String` (`''` when blank), for a
/// partial update.
class UserGuardianFormState extends State<UserGuardianForm>
    with FormContract<UserGuardianForm> {
  @override
  String? crossFieldError(Map<String, dynamic> values) =>
      UserFormValidators.guardianNamed(
        values[UserFormFields.guardianNameId] as String?,
        values[UserFormFields.guardianRelationId] as String?,
        values[UserFormFields.guardianPhoneId] as String?,
      );

  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) =>
      UserFormAssembly.pick(UserFormFields.guardianIds, values);

  @override
  Widget build(BuildContext context) {
    return ShadForm(
      key: formKey,
      initialValue: UserFormAssembly.seed(
        UserFormFields.guardianIds,
        widget.initialValues,
      ),
      child: FormBody(
        error: formError,
        children: [
          UserGuardianFields(
            defaultCountryCode: widget.defaultCountryCode,
            enabled: widget.enabled,
          ),
        ],
      ),
    );
  }
}
