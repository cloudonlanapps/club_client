import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/form_spacing.dart';
import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../signup/username_confirmation.dart';
import 'user_contact_fields.dart';
import 'user_default_password_field.dart';
import 'user_form_assembly.dart';
import 'user_form_fields.dart';
import 'user_form_validators.dart';
import 'user_gender_dob_fields.dart';
import 'user_name_fields.dart';
import 'user_password_fields.dart';
import 'user_role_fields.dart';
import 'user_username_field.dart';

/// Pure-UI form that creates a user (no SDK / no Riverpod), fields only,
/// keyed by [UserFormFields] ids; the host adapts to the SDK (see
/// `cl_club_members` `user_form_helpers.dart`).
///
/// It asks for a username with its availability check, the password (or
/// the default one), names, gender, date of birth, phone, email and the
/// roles the viewer may grant. An existing user is edited section by
/// section (`UserPersonalDetailsForm`, `UserContactForm`,
/// `UserAddressForm`).
///
/// The host drives it through a `GlobalKey<UserFormState>` — `validate()`,
/// `isDirty`, `showErrors()` ([FormContract]) — and keeps its save action
/// off until [onCanSubmitChanged] reports true.
class UserForm extends StatefulWidget {
  const UserForm({
    required this.onCheckUsernameAvailable,
    required this.defaultCountryCode,
    this.initialValues,
    this.onShowDefaultPassword,
    this.enabled = true,
    this.canAssignAdmin = false,
    this.canAssignCoach = false,
    this.onCanSubmitChanged,
    super.key,
  });

  /// Pre-fill values keyed by field id; null means an empty form.
  final Map<String, dynamic>? initialValues;

  /// Resolves to true when the username is free.
  final Future<bool> Function(String username) onCheckUsernameAvailable;

  /// The club's country calling code (digits only, as the server reports
  /// it: `91`); a phone typed without a country code is checked as a
  /// number of that country.
  final String defaultCountryCode;

  /// Shows the default password; null hides the action beside the tick.
  final VoidCallback? onShowDefaultPassword;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  /// Whether the admin tick shows (super admin only).
  final bool canAssignAdmin;

  /// Whether the coach tick shows (admin or super admin).
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

  @override
  bool get asksForUsername => true;

  /// Follows the default-password tick: ticked, the password fields go and
  /// what was typed into them is cleared.
  void onUseDefaultPasswordChanged({required bool useDefault}) {
    setState(() => useDefaultPassword = useDefault);
    final form = formKey.currentState;
    if (useDefault && form != null) UserPasswordFields.clear(form);
  }

  @override
  ValueChanged<bool>? get canSubmitListener => widget.onCanSubmitChanged;

  @override
  String? crossFieldError(Map<String, dynamic> values) {
    final problem =
        usernameProblem() ??
        (!useDefaultPassword
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
                  UserUsernameField(
                    enabled: enabled,
                    onAvailabilityChanged: onAvailabilityChanged,
                    checkAvailability: widget.onCheckUsernameAvailable,
                  ),
                  UserDefaultPasswordField(
                    value: useDefaultPassword,
                    enabled: enabled,
                    onChanged: (value) =>
                        onUseDefaultPasswordChanged(useDefault: value),
                    onShow: widget.onShowDefaultPassword,
                  ),
                  if (!useDefaultPassword) UserPasswordFields(enabled: enabled),
                  UserNameFields(enabled: enabled),
                  UserGenderDobFields(enabled: enabled),
                  UserContactFields(
                    defaultCountryCode: widget.defaultCountryCode,
                    enabled: enabled,
                    emailFirst: false,
                  ),
                ],
              ),
              if (widget.canAssignAdmin || widget.canAssignCoach)
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
