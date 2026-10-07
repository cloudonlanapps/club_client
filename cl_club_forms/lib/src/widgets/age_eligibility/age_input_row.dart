import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/labeled_form_row.dart';

/// One age of the cluster: a labelled row of three number inputs, years,
/// months and days, each its own labelled form field.
class AgeInputRow extends StatelessWidget {
  const AgeInputRow({
    required this.title,
    required this.yearsId,
    required this.monthsId,
    required this.daysId,
    this.enabled = true,
    super.key,
  });

  /// The row's label, e.g. `Minimum age`.
  final String title;

  /// Field id of the years input.
  final String yearsId;

  /// Field id of the months input.
  final String monthsId;

  /// Field id of the days input.
  final String daysId;

  /// Whether the inputs accept text.
  final bool enabled;

  static const String yearsLabel = 'Years';
  static const String monthsLabel = 'Months';
  static const String daysLabel = 'Days';

  /// Gap between the three inputs.
  static const double inputGap = 8;

  @override
  Widget build(BuildContext context) {
    return LabeledFormRow(
      label: title,
      field: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: inputGap,
        children: [
          for (final (id, label) in [
            (yearsId, yearsLabel),
            (monthsId, monthsLabel),
            (daysId, daysLabel),
          ])
            Expanded(
              child: LabeledFormRow(
                label: label,
                field: ShadInputFormField(
                  id: id,
                  enabled: enabled,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
