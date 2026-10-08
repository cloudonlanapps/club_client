import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/labeled_form_row.dart';

/// One labelled text input of a club identity section form, registered with
/// the enclosing `ShadForm` under [id] and keyed `clubIdentity.<id>` so
/// tests and the integration suite can reach it. Its initial text is the
/// form's initial value for [id].
class ClubIdentityTextInput extends StatelessWidget {
  const ClubIdentityTextInput({
    required this.id,
    required this.label,
    required this.keyboardType,
    required this.enabled,
    this.validator,
    this.description,
    this.multiline = false,
    super.key,
  });

  /// What the key of every input starts with; the field id follows.
  static const String keyPrefix = 'clubIdentity.';

  /// Fewest lines of a [multiline] input.
  static const int multilineMinLines = 2;

  /// Most lines of a [multiline] input.
  static const int multilineMaxLines = 4;

  /// The key of the input registered under [id].
  static Key keyOf(String id) => ValueKey('$keyPrefix$id');

  /// The form field id.
  final String id;

  /// The label above the input.
  final String label;

  /// The keyboard the input asks for.
  final TextInputType keyboardType;

  /// Whether the input responds; the form's own `enabled`.
  final bool enabled;

  /// Checks the text; null when the field takes any.
  final String? Function(String)? validator;

  /// Help shown under the input.
  final String? description;

  /// Two to four lines instead of one.
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    final help = description;
    return LabeledFormRow(
      label: label,
      field: ShadInputFormField(
        key: keyOf(id),
        id: id,
        enabled: enabled,
        description: help == null ? null : Text(help),
        keyboardType: multiline ? TextInputType.multiline : keyboardType,
        minLines: multiline ? multilineMinLines : null,
        maxLines: multiline ? multilineMaxLines : 1,
        autocorrect: keyboardType == TextInputType.text,
        validator: validator,
      ),
    );
  }
}
