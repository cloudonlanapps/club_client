import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'user_form_strings.dart';

/// A select of the extended profile that may be left blank: a "None"
/// choice (the value `''`) above the club's [options]. A value the field
/// holds that is not among [options] (an option the club removed later)
/// shows as it is and is offered too, so it is kept unless changed.
///
/// Sits inside the embedding form's `ShadForm`, which holds the value.
class UserOptionalChoiceField extends StatelessWidget {
  const UserOptionalChoiceField({
    required this.id,
    required this.options,
    this.enabled = true,
    super.key,
  });

  /// The field's id.
  final String id;

  /// The choices, value to the text shown, in order.
  final Map<String, String> options;

  /// Whether the field responds.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final held = ShadForm.of(context).initialValue[id] as String? ?? '';
    final shown = {
      '': UserFormStrings.noChoice,
      ...options,
      if (held.isNotEmpty && !options.containsKey(held)) held: held,
    };
    return ShadSelectFormField<String>(
      id: id,
      initialValue: held,
      enabled: enabled,
      options: [
        for (final entry in shown.entries)
          ShadOption(value: entry.key, child: Text(entry.value)),
      ],
      selectedOptionBuilder: (context, value) => Text(shown[value] ?? value),
    );
  }
}
