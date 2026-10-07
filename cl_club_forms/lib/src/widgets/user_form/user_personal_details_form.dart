import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/form_contract.dart';
import 'user_field_pair.dart';
import 'user_form_assembly.dart';
import 'user_form_fields.dart';
import 'user_form_validators.dart';
import 'user_gender_dob_fields.dart';
import 'user_name_fields.dart';
import 'user_public_name_fields.dart';

/// Pure-UI editor for a user's personal details — names, nickname, the
/// public-name flag, gender and date of birth (the "Personal details"
/// profile section).
///
/// Date of birth and gender are protected fields: editable only when
/// [canEditDateOfBirth] / [canEditGender] is true (super-admin). When not
/// editable they show read-only and are left out of the values, so the
/// partial update never trips the server's protected-field guard.
///
/// The form owns no title or buttons: the host drives it through a
/// `GlobalKey<UserPersonalDetailsFormState>` ([FormContract]).
class UserPersonalDetailsForm extends StatefulWidget {
  const UserPersonalDetailsForm({
    required this.initialValues,
    this.enabled = true,
    this.canEditDateOfBirth = false,
    this.canEditGender = false,
    this.canEditUseNamePublicly = false,
    this.canEditPublicProfile = false,
    super.key,
  });

  /// Initial values; reads the ids of
  /// [UserFormFields.personalDetailsIds].
  final Map<String, dynamic> initialValues;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  /// Whether date of birth is a field.
  final bool canEditDateOfBirth;

  /// Whether gender is a field.
  final bool canEditGender;

  /// Whether the public-name flag is a field.
  final bool canEditUseNamePublicly;

  /// Whether the **coach-owned** public-profile controls show: a
  /// public-profile tick and the public-name tick, the latter off unless
  /// the profile is public. The host sets this only when the viewer is the
  /// user themselves and a coach.
  final bool canEditPublicProfile;

  @override
  State<UserPersonalDetailsForm> createState() =>
      UserPersonalDetailsFormState();
}

/// State of [UserPersonalDetailsForm]. Its values are the names and the
/// nickname and, only where the viewer may edit them, `genderId`,
/// `dateOfBirthUtcId`, `useNamePubliclyId` and `isPublicProfileId`.
class UserPersonalDetailsFormState extends State<UserPersonalDetailsForm>
    with FormContract<UserPersonalDetailsForm> {
  @override
  String? crossFieldError(Map<String, dynamic> values) =>
      UserFormValidators.atLeastOneName(
        values[UserFormFields.firstNameId] as String?,
        values[UserFormFields.lastNameId] as String?,
      );

  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) => {
    ...UserFormAssembly.pick(const [
      UserFormFields.firstNameId,
      UserFormFields.middleNameId,
      UserFormFields.lastNameId,
      UserFormFields.nicknameId,
    ], values),
    if (widget.canEditGender)
      UserFormFields.genderId: values[UserFormFields.genderId],
    if (widget.canEditDateOfBirth)
      UserFormFields.dateOfBirthUtcId: values[UserFormFields.dateOfBirthUtcId],
    if (widget.canEditPublicProfile)
      UserFormFields.isPublicProfileId:
          values[UserFormFields.isPublicProfileId] as bool? ?? false,
    if (widget.canEditPublicProfile || widget.canEditUseNamePublicly)
      UserFormFields.useNamePubliclyId: UserPublicNameFields.useNamePublicly(
        values,
        canEditPublicProfile: widget.canEditPublicProfile,
      ),
  };

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    return ShadForm(
      key: formKey,
      initialValue: UserFormAssembly.seed(
        UserFormFields.personalDetailsIds,
        widget.initialValues,
      ),
      child: FormBody(
        error: formError,
        children: [
          UserNameFields(
            enabled: enabled,
            showNickname: true,
            pairMinWidth: UserFieldPair.never,
          ),
          UserPublicNameFields(
            enabled: enabled,
            canEditUseNamePublicly: widget.canEditUseNamePublicly,
            canEditPublicProfile: widget.canEditPublicProfile,
          ),
          UserGenderDobFields(
            enabled: enabled,
            canEditGender: widget.canEditGender,
            canEditDateOfBirth: widget.canEditDateOfBirth,
            pairMinWidth: UserFieldPair.never,
          ),
        ],
      ),
    );
  }
}
