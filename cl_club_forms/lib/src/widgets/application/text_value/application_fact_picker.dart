import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../models/application/application_fact_type.dart';
import '../application_form_strings.dart';

/// A select of the template's facts: those of one type, or all of them. A
/// chosen fact the list no longer has (renamed, removed) shows as it is and
/// is offered too, so the choice is kept unless changed.
class ApplicationFactPicker extends StatelessWidget {
  const ApplicationFactPicker({
    required this.facts,
    required this.value,
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  /// The facts offered: the type of each, by name, in order.
  final Map<String, ApplicationFactType> facts;

  /// The chosen fact; `''` for none.
  final String value;

  /// Whether the select responds.
  final bool enabled;

  /// Called with the chosen fact's name.
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final shown = {
      for (final entry in facts.entries)
        entry.key: ApplicationFormStrings.factOption(entry.key, entry.value),
      if (value.isNotEmpty && !facts.containsKey(value)) value: value,
    };
    return ShadSelect<String>(
      initialValue: value.isEmpty ? null : value,
      enabled: enabled,
      placeholder: const Text(ApplicationFormStrings.chooseFactHint),
      options: [
        for (final entry in shown.entries)
          ShadOption(value: entry.key, child: Text(entry.value)),
      ],
      selectedOptionBuilder: (context, name) => Text(shown[name] ?? name),
      onChanged: (name) {
        if (name != null) onChanged(name);
      },
    );
  }
}
