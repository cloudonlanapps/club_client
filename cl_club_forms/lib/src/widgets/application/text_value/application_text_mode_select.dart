import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../form/labeled_form_row.dart';
import '../application_form_strings.dart';
import '../application_text_mode.dart';

/// Where a printed text comes from, picked among [modes].
class ApplicationTextModeSelect extends StatelessWidget {
  const ApplicationTextModeSelect({
    required this.modes,
    required this.value,
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  /// The modes offered, in order.
  final List<ApplicationTextMode> modes;

  /// The chosen mode.
  final ApplicationTextMode value;

  /// Whether the select responds.
  final bool enabled;

  /// Called with the chosen mode.
  final ValueChanged<ApplicationTextMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return LabeledFormRow(
      label: ApplicationFormStrings.textFrom,
      field: ShadSelect<ApplicationTextMode>(
        initialValue: value,
        enabled: enabled,
        options: [
          for (final mode in modes)
            ShadOption(
              value: mode,
              child: Text(ApplicationFormStrings.modeName(mode)),
            ),
        ],
        selectedOptionBuilder: (context, mode) =>
            Text(ApplicationFormStrings.modeName(mode)),
        onChanged: (mode) {
          if (mode != null) onChanged(mode);
        },
      ),
    );
  }
}
