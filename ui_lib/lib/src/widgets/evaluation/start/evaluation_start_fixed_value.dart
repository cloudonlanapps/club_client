import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../labeled_form_row.dart';

/// A value of the start form its host has fixed — the template, the member
/// or the event — shown under its [label] in place of the select.
class EvaluationStartFixedValue extends StatelessWidget {
  /// Shows [value] under [label].
  const EvaluationStartFixedValue({
    required this.label,
    required this.value,
    super.key,
  });

  /// Padding of the value inside its box.
  static const EdgeInsets valuePadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 10,
  );

  /// The row's label.
  final String label;

  /// The value shown.
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return LabeledFormRow(
      label: label,
      field: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.muted,
          borderRadius: theme.radius,
        ),
        child: Padding(
          padding: valuePadding,
          child: Text(value, style: theme.textTheme.p),
        ),
      ),
    );
  }
}
