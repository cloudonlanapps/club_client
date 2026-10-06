import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// One age of the cluster: a title above three number inputs, years, months
/// and days, each its own form field.
class AgeInputRow extends StatelessWidget {
  const AgeInputRow({
    required this.title,
    required this.yearsId,
    required this.monthsId,
    required this.daysId,
    this.enabled = true,
    super.key,
  });

  final String title;
  final String yearsId;
  final String monthsId;
  final String daysId;
  final bool enabled;

  static const String yearsLabel = 'Years';
  static const String monthsLabel = 'Months';
  static const String daysLabel = 'Days';

  /// Gap between the title and the inputs, and between the inputs.
  static const double gap = 8;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: gap,
      children: [
        Text(
          title,
          style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: gap,
          children: [
            for (final (id, label) in [
              (yearsId, yearsLabel),
              (monthsId, monthsLabel),
              (daysId, daysLabel),
            ])
              Expanded(
                child: ShadInputFormField(
                  id: id,
                  label: Text(label),
                  enabled: enabled,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
