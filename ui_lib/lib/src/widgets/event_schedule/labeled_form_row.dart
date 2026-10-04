import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Form-row helper that renders a label above its field.
///
/// One consistent layout for every screen size: the label sits on its own
/// line, with the field stretched below. Avoids the inline-label pattern
/// because the form's mixed control widths (date picker, time picker,
/// shad input) never line up cleanly when labels share their row.
class LabeledFormRow extends StatelessWidget {
  const LabeledFormRow({
    required this.field,
    this.label,
    this.labelChild,
    this.required = false,
    super.key,
  }) : assert(
         label != null || labelChild != null,
         'Either label or labelChild must be provided',
       );

  /// Plain text label. Adds " *" automatically when [required] is true.
  /// Ignored when [labelChild] is provided.
  final String? label;

  /// Custom label widget (e.g. a tap-to-toggle row of Texts). Takes
  /// precedence over [label].
  final Widget? labelChild;
  final Widget field;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final labelWidget =
        labelChild ??
        Text(
          required ? '${label!} *' : label!,
          style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Align(alignment: Alignment.centerLeft, child: labelWidget),
        field,
      ],
    );
  }
}
