import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'form/labeled_form_row.dart';

/// A labelled row showing a value the current form does not edit (for
/// example, a username that cannot change).
class ReadOnlyField extends StatelessWidget {
  const ReadOnlyField({
    required this.label,
    required this.value,
    super.key,
  });

  /// Padding of the value inside its box.
  static const EdgeInsets valuePadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 10,
  );

  /// Corner radius of the value's box.
  static const double radius = 6;

  /// The row's label.
  final String label;

  /// The value shown.
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return LabeledFormRow(
      label: label,
      field: Container(
        width: double.infinity,
        padding: valuePadding,
        decoration: BoxDecoration(
          color: theme.colorScheme.muted,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Text(value, style: theme.textTheme.p),
      ),
    );
  }
}
