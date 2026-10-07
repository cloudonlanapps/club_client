import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/form_spacing.dart';
import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../read_only_field.dart';
import '../signup/username_confirmation.dart';
import 'user_contact_fields.dart';
import 'user_default_password_field.dart';
import 'user_edit_only_fields.dart';
import 'user_form_assembly.dart';
import 'user_form_fields.dart';
import 'user_form_strings.dart';
import 'user_form_validators.dart';
import 'user_gender_dob_fields.dart';
import 'user_name_fields.dart';
import 'user_password_fields.dart';
import 'user_public_name_fields.dart';
import 'user_role_fields.dart';
import 'user_username_field.dart';

/// Pure-UI user form (no SDK / no Riverpod), fields only, keyed by
/// [UserFormFields] ids; the host adapts to and from the SDK (see
/// `cl_club_members` `user_form_helpers.dart`).
///
/// With [readOnlyUsername] null the form **creates**: a username with its
/// availability check, the password (or the default one), names, gender,
/// date of birth, phone, email and the roles the viewer may grant. With it
/// given the form **edits**: the username shows read-only, the password is
/// absent, and nickname, public name, address, emergency contact and
/// medical notes are added.
///
/// The host drives it through a `GlobalKey<UserFormState>` — `validate()`,
/// `isDirty`, `showErrors()` ([FormContract]) — and, while creating, keeps
/// its save action off until [onCanSubmitChanged] reports true.
class UserForm extends StatefulWidget {
  const UserForm({
    this.readOnlyUsername,
    this.initialValues,
    this.onCheckUsernameAvailable,
    this.onShowDefaultPassword,
    this.enabled = true,
    this.canEditDateOfBirth = false,
    this.canEditGender = false,
    this.canEditUseNamePublicly = false,
    this.canAssignAdmin = false,
    this.canAssignCoach = false,
    this.onCanSubmitChanged,
    super.key,
  }) : assert(
         readOnlyUsername != null || onCheckUsernameAvailable != null,
         'a creating UserForm requires onCheckUsernameAvailable',
       );

  /// Null while creating; when editing, the username shown read-only.
  final String? readOnlyUsername;

  /// Pre-fill values keyed by field id; null means an empty form.
  final Map<String, dynamic>? initialValues;

  /// Resolves to true when the username is free; required while creating.
  final Future<bool> Function(String username)? onCheckUsernameAvailable;

  /// Shows the default password; null hides the action beside the tick.
  final VoidCallback? onShowDefaultPassword;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  /// Whether date of birth is a field while editing (always, creating).
  final bool canEditDateOfBirth;

  /// Whether gender is a field while editing (always, creating).
  final bool canEditGender;

  /// Whether the public-name flag is a field while editing.
  final bool canEditUseNamePublicly;

  /// Whether the admin tick shows while creating (super admin only).
  final bool canAssignAdmin;

  /// Whether the coach tick shows while creating (admin or super admin).
  final bool canAssignCoach;

  /// Hears whether the form may be submitted (`UsernameConfirmation`).
  final ValueChanged<bool>? onCanSubmitChanged;

  @override
  State<UserForm> createState() => UserFormState();
}

/// State of [UserForm]. Its values are the form's fields as typed, keyed by
/// [UserFormFields] ids; the host's adapter trims and assembles them.
class UserFormState extends State<UserForm>
    with FormContract<UserForm>, UsernameConfirmation<UserForm> {
  /// Whether a created account gets the default password; off shows the
  /// password fields.
  bool useDefaultPassword = true;

  /// Whether the form creates a user (as opposed to editing one).
  bool get isCreate => widget.readOnlyUsername == null;

  @override
  bool get asksForUsername => isCreate;

  @override
  ValueChanged<bool>? get canSubmitListener => widget.onCanSubmitChanged;

  @override
  String? crossFieldError(Map<String, dynamic> values) {
    final problem =
        usernameProblem() ??
        (isCreate && !useDefaultPassword
            ? UserFormValidators.passwordsMatch(
                values[UserFormFields.passwordId] as String?,
                values[UserFormFields.confirmPasswordId] as String?,
              )
            : null);
    return problem ??
        UserFormValidators.atLeastOneName(
          values[UserFormFields.firstNameId] as String?,
          values[UserFormFields.lastNameId] as String?,
        );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    final username = widget.readOnlyUsername;
    return ShadForm(
      key: formKey,
      initialValue: UserFormAssembly.seed(
        UserFormFields.userIds,
        widget.initialValues,
      ),
      child: FormBody(
        error: formError,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: FormSpacing.sectionGap,
            children: [
              FormBody(
                children: [
                  if (username != null)
                    ReadOnlyField(
                      label: UserFormStrings.username,
                      value: username,
                    )
                  else ...[
                    UserUsernameField(
                      enabled: enabled,
                      onAvailabilityChanged: onAvailabilityChanged,
                      checkAvailability: widget.onCheckUsernameAvailable!,
                    ),
                    UserDefaultPasswordField(
                      value: useDefaultPassword,
                      enabled: enabled,
                      onChanged: (value) =>
                          setState(() => useDefaultPassword = value),
                      onShow: widget.onShowDefaultPassword,
                    ),
                    if (!useDefaultPassword)
                      UserPasswordFields(enabled: enabled),
                  ],
                  UserNameFields(
                    enabled: enabled,
                    showNickname: !isCreate,
                    autofocus: !isCreate,
                  ),
                  if (!isCreate)
                    UserPublicNameFields(
                      enabled: enabled,
                      canEditUseNamePublicly: widget.canEditUseNamePublicly,
                    ),
                  UserGenderDobFields(
                    enabled: enabled,
                    canEditGender: isCreate || widget.canEditGender,
                    canEditDateOfBirth: isCreate || widget.canEditDateOfBirth,
                  ),
                  if (isCreate)
                    UserContactFields(enabled: enabled, emailFirst: false),
                ],
              ),
              if (!isCreate) UserEditOnlyFields(enabled: enabled),
              if (isCreate && (widget.canAssignAdmin || widget.canAssignCoach))
                UserRoleFields(
                  enabled: enabled,
                  canAssignAdmin: widget.canAssignAdmin,
                  canAssignCoach: widget.canAssignCoach,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
