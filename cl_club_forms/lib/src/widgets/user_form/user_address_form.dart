import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'indian_states.dart';
import 'user_form_validators.dart';

/// Pure-UI editor for a user's postal address — the "Address" profile section.
///
/// Host-agnostic: embed it (typically in a `ShadDialog`) and drive it through a
/// `GlobalKey<UserAddressFormState>`, calling [UserAddressFormState.validate]
/// from the Save action. Returns a partial value map keyed only by the address
/// fields, so the caller's adapter performs a partial update.
class UserAddressForm extends StatefulWidget {
  const UserAddressForm({required this.initialValues, super.key});

  /// Initial values; reads `addrLine1`, `addrLine2`, `city`, `state`,
  /// `pincode`.
  final Map<String, dynamic> initialValues;

  static const ids = ['addrLine1', 'addrLine2', 'city', 'state', 'pincode'];

  @override
  State<UserAddressForm> createState() => UserAddressFormState();
}

class UserAddressFormState extends State<UserAddressForm> {
  final formKey = GlobalKey<ShadFormState>();

  /// Validates; returns the address field values when valid, else `null`.
  Map<String, dynamic>? validate() {
    final form = formKey.currentState;
    if (form == null || !form.saveAndValidate()) return null;
    return {for (final id in UserAddressForm.ids) id: form.value[id]};
  }

  /// Whether any address field differs from its initial value (text fields
  /// normalize `null` ↔ `''`).
  bool get isDirty {
    final form = formKey.currentState;
    if (form == null) return false;
    return UserAddressForm.ids.any(
      (id) => (form.value[id] ?? '') != (widget.initialValues[id] ?? ''),
    );
  }

  String _initial(String id) => widget.initialValues[id] as String? ?? '';

  @override
  Widget build(BuildContext context) {
    return ShadForm(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ShadInputFormField(
            id: 'addrLine1',
            label: const Text('Address line 1'),
            initialValue: _initial('addrLine1'),
            keyboardType: TextInputType.streetAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          ShadInputFormField(
            id: 'addrLine2',
            label: const Text('Address line 2'),
            initialValue: _initial('addrLine2'),
            keyboardType: TextInputType.streetAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          ShadInputFormField(
            id: 'city',
            label: const Text('City'),
            initialValue: _initial('city'),
            keyboardType: TextInputType.streetAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          ShadSelectFormField<String>(
            id: 'state',
            label: const Text('State'),
            initialValue: widget.initialValues['state'] as String?,
            placeholder: const Text('Select state'),
            options: indianStates
                .map((s) => ShadOption(value: s, child: Text(s)))
                .toList(),
            selectedOptionBuilder: (context, value) => Text(value),
          ),
          const SizedBox(height: 12),
          ShadInputFormField(
            id: 'pincode',
            label: const Text('Pincode'),
            initialValue: _initial('pincode'),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            validator: UserFormValidators.pincode,
          ),
        ],
      ),
    );
  }
}
