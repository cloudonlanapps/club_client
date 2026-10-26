import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/labeled_form_row.dart';
import 'user_form_fields.dart';
import 'user_form_strings.dart';
import 'user_form_validators.dart';

/// The guardian of the extended profile (name, relation, phone), apart
/// from the emergency contact. Sits inside the embedding form's `ShadForm`,
/// which holds the initial values.
class UserGuardianFields extends StatelessWidget {
  const UserGuardianFields({
    required this.defaultCountryCode,
    this.enabled = true,
    super.key,
  });

  /// The club's country calling code (digits only, as the server reports
  /// it: `91`); the guardian's phone typed without a country code is
  /// checked as a number of that country.
  final String defaultCountryCode;

  /// Whether the fields respond.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FormBody(
      children: [
        LabeledFormRow(
          label: UserFormStrings.guardianName,
          field: ShadInputFormField(
            id: UserFormFields.guardianNameId,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            enabled: enabled,
          ),
        ),
        LabeledFormRow(
          label: UserFormStrings.guardianRelation,
          field: ShadInputFormField(
            id: UserFormFields.guardianRelationId,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            enabled: enabled,
          ),
        ),
        LabeledFormRow(
          label: UserFormStrings.guardianPhone,
          field: ShadInputFormField(
            id: UserFormFields.guardianPhoneId,
            keyboardType: TextInputType.phone,
            enabled: enabled,
            validator: (value) => UserFormValidators.phoneOptional(
              value,
              defaultCountryCode: defaultCountryCode,
            ),
          ),
        ),
      ],
    );
  }
}
