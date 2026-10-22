import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../read_only_field.dart';
import '../user_form/user_contact_fields.dart';
import '../user_form/user_field_pair.dart';
import '../user_form/user_form_assembly.dart';
import '../user_form/user_form_fields.dart';
import '../user_form/user_form_strings.dart';
import '../user_form/user_form_validators.dart';
import '../user_form/user_gender_dob_fields.dart';
import '../user_form/user_name_fields.dart';
import '../user_form/user_password_fields.dart';
import '../user_form/user_username_field.dart';
import 'signup_gender.dart';

/// Pure-UI registration form (no SDK / no Riverpod), in one of two modes
/// decided by [username]:
///
/// - `username == null`, signing up: an editable username, a password and
///   its confirmation.
/// - `username != null`, reapplying: that username read-only, no password.
///
/// Names, gender, date of birth, phone and email are edited in both.
/// Pre-fill via [initialValues] (field id → value, ids in
/// [UserFormFields]).
///
/// The form owns no title, buttons or links: the host drives it through a
/// `GlobalKey<SignupFormState>` — `validate()` from its submit action,
/// `showErrors()` with what the server refuses ([FormContract]), a taken
/// username among it.
class SignupForm extends StatefulWidget {
  const SignupForm({
    required this.defaultCountryCode,
    this.username,
    this.initialValues,
    this.enabled = true,
    super.key,
  });

  /// Years before today the date-of-birth picker offers.
  static const int dateOfBirthYearsBefore = 100;

  /// Years after today the date-of-birth picker offers.
  static const int dateOfBirthYearsAfter = 0;

  /// The mode: null while signing up, the member's username when
  /// reapplying.
  final String? username;

  /// The club's country calling code (digits only, as the server reports
  /// it: `91`); a phone typed without a country code is checked as a
  /// number of that country.
  final String defaultCountryCode;

  /// Pre-fill values keyed by field id; null means an empty form.
  final Map<String, dynamic>? initialValues;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  @override
  State<SignupForm> createState() => SignupFormState();
}

/// State of [SignupForm]. Its values, keyed by [UserFormFields] ids:
/// `usernameId` (trimmed) and `passwordId` while signing up only; `emailId`
/// and `phoneId` trimmed; `firstNameId`, `middleNameId` and `lastNameId`
/// trimmed, null when empty; `dateOfBirthUtcId` floored to UTC midnight;
/// `genderId` as a [SignupGender].
class SignupFormState extends State<SignupForm> with FormContract<SignupForm> {
  /// Whether this form asks for a username: signing up does, reapplying
  /// shows the member's own.
  bool get asksForUsername => widget.username == null;

  @override
  String? crossFieldError(Map<String, dynamic> values) {
    final nameProblem = UserFormValidators.atLeastOneName(
      values[UserFormFields.firstNameId] as String?,
      values[UserFormFields.lastNameId] as String?,
    );
    if (nameProblem != null || !asksForUsername) return nameProblem;
    return UserFormValidators.passwordsMatch(
      values[UserFormFields.passwordId] as String?,
      values[UserFormFields.confirmPasswordId] as String?,
    );
  }

  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) => {
    if (asksForUsername) ...{
      UserFormFields.usernameId: (values[UserFormFields.usernameId] as String)
          .trim(),
      UserFormFields.passwordId: values[UserFormFields.passwordId] as String,
    },
    UserFormFields.emailId: (values[UserFormFields.emailId] as String).trim(),
    UserFormFields.phoneId: (values[UserFormFields.phoneId] as String).trim(),
    for (final id in const [
      UserFormFields.firstNameId,
      UserFormFields.middleNameId,
      UserFormFields.lastNameId,
    ])
      id: UserFormAssembly.maybe(id, values),
    UserFormFields.dateOfBirthUtcId: UserFormAssembly.floorToUtcMidnight(
      values[UserFormFields.dateOfBirthUtcId] as DateTime?,
    ),
    UserFormFields.genderId: values[UserFormFields.genderId] as SignupGender?,
  };

  @override
  Widget build(BuildContext context) {
    final username = widget.username;
    final enabled = widget.enabled;
    return ShadForm(
      key: formKey,
      initialValue: UserFormAssembly.seed(
        UserFormFields.signupIds,
        widget.initialValues,
      ),
      child: FormBody(
        error: formError,
        children: [
          if (username != null)
            ReadOnlyField(label: UserFormStrings.username, value: username)
          else ...[
            UserUsernameField(enabled: enabled),
            UserPasswordFields(enabled: enabled),
          ],
          UserNameFields(enabled: enabled, pairMinWidth: UserFieldPair.always),
          UserGenderDobFields(
            enabled: enabled,
            pairMinWidth: UserFieldPair.always,
            genderPlaceholder: UserFormStrings.genderShortPlaceholder,
            dateOfBirthPlaceholder: UserFormStrings.dateOfBirthShortPlaceholder,
            yearsBefore: SignupForm.dateOfBirthYearsBefore,
            yearsAfter: SignupForm.dateOfBirthYearsAfter,
          ),
          UserContactFields(
            defaultCountryCode: widget.defaultCountryCode,
            enabled: enabled,
            emailFirst: false,
          ),
        ],
      ),
    );
  }
}
