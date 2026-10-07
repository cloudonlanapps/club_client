import 'package:cl_calendar/cl_calendar.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/labeled_form_row.dart';
import '../read_only_field.dart';
import '../signup/signup_gender.dart';
import 'user_field_pair.dart';
import 'user_form_fields.dart';
import 'user_form_strings.dart';
import 'user_form_validators.dart';

/// Gender and date of birth, shared by the user forms. Sits inside the
/// embedding form's `ShadForm`, which holds the initial values.
///
/// Both are protected: with [canEditGender] / [canEditDateOfBirth] off the
/// value shows read-only and no field is registered, so the form's values
/// carry no key for it.
class UserGenderDobFields extends StatelessWidget {
  const UserGenderDobFields({
    this.enabled = true,
    this.canEditGender = true,
    this.canEditDateOfBirth = true,
    this.pairMinWidth = UserFieldPair.sideBySideMinWidth,
    this.genderPlaceholder = UserFormStrings.genderPlaceholder,
    this.dateOfBirthPlaceholder = UserFormStrings.dateOfBirthPlaceholder,
    this.yearsBefore = defaultYears,
    this.yearsAfter = defaultYears,
    super.key,
  });

  /// Years the date picker offers either side of today unless told
  /// otherwise.
  static const int defaultYears = 50;

  /// Whether the fields respond.
  final bool enabled;

  /// Whether gender is a field; otherwise it shows read-only.
  final bool canEditGender;

  /// Whether date of birth is a field; otherwise it shows read-only.
  final bool canEditDateOfBirth;

  /// Width from which the two sit side by side.
  final double pairMinWidth;

  /// Hint in the empty gender select.
  final String genderPlaceholder;

  /// Hint in the empty date-of-birth field.
  final String dateOfBirthPlaceholder;

  /// Years before today the date picker offers.
  final int yearsBefore;

  /// Years after today the date picker offers.
  final int yearsAfter;

  @override
  Widget build(BuildContext context) {
    final initial = ShadForm.of(context).initialValue;
    final gender = initial[UserFormFields.genderId] as SignupGender?;
    final dateOfBirth = initial[UserFormFields.dateOfBirthUtcId] as DateTime?;
    final dateFormat = DateFormat(UserFormStrings.dateFormat);

    return UserFieldPair(
      minWidth: pairMinWidth,
      first: canEditGender
          ? LabeledFormRow(
              label: UserFormStrings.gender,
              required: true,
              field: ShadSelectFormField<SignupGender>(
                id: UserFormFields.genderId,
                initialValue: gender,
                placeholder: Text(genderPlaceholder),
                enabled: enabled,
                validator: UserFormValidators.gender,
                options: [
                  for (final option in SignupGender.values)
                    ShadOption(value: option, child: Text(option.label)),
                ],
                selectedOptionBuilder: (context, value) => Text(value.label),
              ),
            )
          : ReadOnlyField(
              label: UserFormStrings.gender,
              value: gender?.label ?? UserFormStrings.notSet,
            ),
      second: canEditDateOfBirth
          ? LabeledFormRow(
              label: UserFormStrings.dateOfBirth,
              required: true,
              field: CLDatePickerFormField(
                id: UserFormFields.dateOfBirthUtcId,
                initialValue: dateOfBirth,
                placeholder: Text(dateOfBirthPlaceholder),
                enabled: enabled,
                formatDate: dateFormat.format,
                validator: UserFormValidators.dateOfBirth,
                yearsBefore: yearsBefore,
                yearsAfter: yearsAfter,
              ),
            )
          : ReadOnlyField(
              label: UserFormStrings.dateOfBirth,
              value: dateOfBirth != null
                  ? dateFormat.format(dateOfBirth)
                  : UserFormStrings.notSet,
            ),
    );
  }
}
