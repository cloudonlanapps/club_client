import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/labeled_form_row.dart';
import 'user_field_pair.dart';
import 'user_form_assembly.dart';
import 'user_form_fields.dart';
import 'user_form_strings.dart';
import 'user_form_validators.dart';

/// The emergency contact (name, relation, phone) and the medical notes,
/// shared by the user forms. Sits inside the embedding form's `ShadForm`,
/// which holds the initial values.
class UserEmergencyFields extends StatelessWidget {
  const UserEmergencyFields({
    this.enabled = true,
    this.pairMinWidth = UserFieldPair.sideBySideMinWidth,
    super.key,
  });

  /// Fewest lines the medical notes show.
  static const int medicalInfoMinLines = 2;

  /// Most lines the medical notes grow to.
  static const int medicalInfoMaxLines = 4;

  /// Whether the fields respond.
  final bool enabled;

  /// Width from which relation and phone sit side by side.
  final double pairMinWidth;

  @override
  Widget build(BuildContext context) {
    final initial = ShadForm.of(context).initialValue;
    return FormBody(
      children: [
        LabeledFormRow(
          label: UserFormStrings.emergencyContactName,
          field: ShadInputFormField(
            id: UserFormFields.emergencyContactNameId,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            enabled: enabled,
          ),
        ),
        UserFieldPair(
          minWidth: pairMinWidth,
          first: LabeledFormRow(
            label: UserFormStrings.emergencyContactRelation,
            field: ShadSelectFormField<String>(
              id: UserFormFields.emergencyContactRelationId,
              initialValue:
                  initial[UserFormFields.emergencyContactRelationId] as String?,
              placeholder: const Text(
                UserFormStrings.emergencyContactRelationPlaceholder,
              ),
              enabled: enabled,
              options: [
                for (final relation in UserFormAssembly.emergencyRelations)
                  ShadOption(value: relation, child: Text(relation)),
              ],
              selectedOptionBuilder: (context, value) => Text(value),
            ),
          ),
          second: LabeledFormRow(
            label: UserFormStrings.emergencyContactPhone,
            field: ShadInputFormField(
              id: UserFormFields.emergencyContactPhoneId,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              enabled: enabled,
              validator: UserFormValidators.phoneOptional,
            ),
          ),
        ),
        LabeledFormRow(
          label: UserFormStrings.medicalInfo,
          field: ShadInputFormField(
            id: UserFormFields.medicalInfoId,
            keyboardType: TextInputType.multiline,
            minLines: medicalInfoMinLines,
            maxLines: medicalInfoMaxLines,
            enabled: enabled,
          ),
        ),
      ],
    );
  }
}
