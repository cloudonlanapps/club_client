import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../models/application/application_fact_type.dart';
import '../../form/labeled_form_row.dart';
import '../application_form_strings.dart';

/// The type of a fact of an application, picked among every type.
class ApplicationFactTypeSelect extends StatelessWidget {
  const ApplicationFactTypeSelect({
    required this.value,
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  /// The type chosen.
  final ApplicationFactType value;

  /// Whether the select responds.
  final bool enabled;

  /// Called with the type picked.
  final ValueChanged<ApplicationFactType> onChanged;

  @override
  Widget build(BuildContext context) {
    return LabeledFormRow(
      label: ApplicationFormStrings.factType,
      field: ShadSelect<ApplicationFactType>(
        initialValue: value,
        enabled: enabled,
        options: [
          for (final option in ApplicationFactType.values)
            ShadOption(
              value: option,
              child: Text(ApplicationFormStrings.typeName(option)),
            ),
        ],
        selectedOptionBuilder: (context, option) =>
            Text(ApplicationFormStrings.typeName(option)),
        onChanged: (option) {
          if (option != null) onChanged(option);
        },
      ),
    );
  }
}
