import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'user_form_assembly.dart';
import 'user_form_validators.dart';

/// Pure-UI editor for a user's contact info — email, phone, emergency contact,
/// and medical notes (the "Contact" profile section).
///
/// Host-agnostic: embed it (typically in a `ShadDialog`) and drive it through a
/// `GlobalKey<UserContactFormState>`, calling [UserContactFormState.validate]
/// from the Save action. Returns a partial value map for a partial update.
class UserContactForm extends StatefulWidget {
  const UserContactForm({required this.initialValues, super.key});

  /// Reads `email`, `phone`, `emergencyContactName`,
  /// `emergencyContactRelation`, `emergencyContactPhone`, `medicalInfo`.
  final Map<String, dynamic> initialValues;

  static const ids = [
    'email',
    'phone',
    'emergencyContactName',
    'emergencyContactRelation',
    'emergencyContactPhone',
    'medicalInfo',
  ];

  @override
  State<UserContactForm> createState() => UserContactFormState();
}

class UserContactFormState extends State<UserContactForm> {
  final formKey = GlobalKey<ShadFormState>();

  /// Validates; returns the contact field values when valid, else `null`.
  Map<String, dynamic>? validate() {
    final form = formKey.currentState;
    if (form == null || !form.saveAndValidate()) return null;
    return {for (final id in UserContactForm.ids) id: form.value[id]};
  }

  /// Whether any contact field differs from its initial value (text fields
  /// normalize `null` ↔ `''`).
  bool get isDirty {
    final form = formKey.currentState;
    if (form == null) return false;
    return UserContactForm.ids.any(
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
            id: 'email',
            label: const Text('Email'),
            initialValue: _initial('email'),
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.next,
            validator: UserFormValidators.email,
          ),
          const SizedBox(height: 12),
          ShadInputFormField(
            id: 'phone',
            label: const Text('Phone'),
            initialValue: _initial('phone'),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            validator: UserFormValidators.phone,
          ),
          const SizedBox(height: 12),
          ShadInputFormField(
            id: 'emergencyContactName',
            label: const Text('Emergency contact name'),
            initialValue: _initial('emergencyContactName'),
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          ShadSelectFormField<String>(
            id: 'emergencyContactRelation',
            label: const Text('Emergency contact relation'),
            initialValue:
                widget.initialValues['emergencyContactRelation'] as String?,
            placeholder: const Text('Select relation'),
            options: UserFormAssembly.emergencyRelations
                .map((r) => ShadOption(value: r, child: Text(r)))
                .toList(),
            selectedOptionBuilder: (context, value) => Text(value),
          ),
          const SizedBox(height: 12),
          ShadInputFormField(
            id: 'emergencyContactPhone',
            label: const Text('Emergency contact phone'),
            initialValue: _initial('emergencyContactPhone'),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            validator: UserFormValidators.phoneOptional,
          ),
          const SizedBox(height: 12),
          ShadInputFormField(
            id: 'medicalInfo',
            label: const Text('Medical info'),
            initialValue: _initial('medicalInfo'),
            keyboardType: TextInputType.multiline,
            minLines: 2,
            maxLines: 4,
          ),
        ],
      ),
    );
  }
}
