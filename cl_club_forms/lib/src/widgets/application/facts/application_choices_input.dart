import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/form_spacing.dart';
import '../../../models/application/application_choice_option.dart';
import '../application_form_fields.dart';

/// The choices of a fact of type `choices`: a checkbox per choice of the
/// library, by its English text. A ticked choice the library no longer
/// has shows by its id.
class ApplicationChoicesInput extends StatelessWidget {
  const ApplicationChoicesInput({
    required this.options,
    required this.value,
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  /// The library's choices, in order.
  final List<ApplicationChoiceOption> options;

  /// The ids ticked, in order.
  final List<String> value;

  /// Whether the checkboxes respond.
  final bool enabled;

  /// Called with the ids ticked.
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final shown = {
      for (final option in options)
        option.id: option.text[ApplicationFormFields.english] ?? option.id,
      for (final id in value) id: id,
    };
    final known = {for (final option in options) option.id: option.text};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FormSpacing.labelGap,
      children: [
        for (final MapEntry(key: id, value: text) in shown.entries)
          ShadCheckbox(
            value: value.contains(id),
            enabled: enabled,
            label: Text(known[id]?[ApplicationFormFields.english] ?? text),
            onChanged: (ticked) => onChanged([
              for (final option in shown.keys)
                if (option == id ? ticked : value.contains(option)) option,
            ]),
          ),
      ],
    );
  }
}
