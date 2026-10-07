import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/labeled_form_row.dart';
import 'indian_states.dart';
import 'user_field_pair.dart';
import 'user_form_fields.dart';
import 'user_form_strings.dart';
import 'user_form_validators.dart';

/// The postal address, shared by the user forms: two lines, city, state and
/// pincode. Sits inside the embedding form's `ShadForm`, which holds the
/// initial values.
class UserAddressFields extends StatelessWidget {
  const UserAddressFields({
    this.enabled = true,
    this.pairMinWidth = UserFieldPair.sideBySideMinWidth,
    super.key,
  });

  /// Whether the fields respond.
  final bool enabled;

  /// Width from which state and pincode sit side by side.
  final double pairMinWidth;

  @override
  Widget build(BuildContext context) {
    final initial = ShadForm.of(context).initialValue;
    return FormBody(
      children: [
        LabeledFormRow(
          label: UserFormStrings.addrLine1,
          field: ShadInputFormField(
            id: UserFormFields.addrLine1Id,
            keyboardType: TextInputType.streetAddress,
            textInputAction: TextInputAction.next,
            enabled: enabled,
          ),
        ),
        LabeledFormRow(
          label: UserFormStrings.addrLine2,
          field: ShadInputFormField(
            id: UserFormFields.addrLine2Id,
            keyboardType: TextInputType.streetAddress,
            textInputAction: TextInputAction.next,
            enabled: enabled,
          ),
        ),
        LabeledFormRow(
          label: UserFormStrings.city,
          field: ShadInputFormField(
            id: UserFormFields.cityId,
            keyboardType: TextInputType.streetAddress,
            textInputAction: TextInputAction.next,
            enabled: enabled,
          ),
        ),
        UserFieldPair(
          minWidth: pairMinWidth,
          first: LabeledFormRow(
            label: UserFormStrings.state,
            field: ShadSelectFormField<String>(
              id: UserFormFields.stateId,
              initialValue: initial[UserFormFields.stateId] as String?,
              placeholder: const Text(UserFormStrings.statePlaceholder),
              enabled: enabled,
              options: [
                for (final state in indianStates)
                  ShadOption(value: state, child: Text(state)),
              ],
              selectedOptionBuilder: (context, value) => Text(value),
            ),
          ),
          second: LabeledFormRow(
            label: UserFormStrings.pincode,
            field: ShadInputFormField(
              id: UserFormFields.pincodeId,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              enabled: enabled,
              validator: UserFormValidators.pincode,
            ),
          ),
        ),
      ],
    );
  }
}
