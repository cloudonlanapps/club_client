import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// One text input of `ClubIdentityForm`, registered with the enclosing
/// `ShadForm` under [id] and keyed `clubIdentity.<id>` so tests and the
/// integration suite can reach it.
class ClubIdentityTextInput extends StatelessWidget {
  const ClubIdentityTextInput({
    required this.id,
    required this.label,
    required this.initialValue,
    required this.keyboardType,
    this.validator,
    this.description,
    this.multiline = false,
    super.key,
  });

  /// The form field id.
  final String id;

  final String label;
  final String initialValue;
  final TextInputType keyboardType;
  final String? Function(String)? validator;

  /// Help shown under the input.
  final String? description;

  /// Two to four lines instead of one.
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    final help = description;
    return ShadInputFormField(
      key: ValueKey('clubIdentity.$id'),
      id: id,
      label: Text(label),
      description: help == null ? null : Text(help),
      initialValue: initialValue,
      keyboardType: multiline ? TextInputType.multiline : keyboardType,
      minLines: multiline ? 2 : null,
      maxLines: multiline ? 4 : 1,
      autocorrect: keyboardType == TextInputType.text,
      validator: validator,
    );
  }
}
