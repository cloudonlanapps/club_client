import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/form_spacing.dart';

/// One labelled row of a form: the label above its field.
///
/// The one way a form labels a field, composite fields included, so every
/// form has the same label style, the same required mark and the same gap.
/// The label sits on its own line with the field stretched below, on every
/// screen size: a label sharing its row never lines up across the forms'
/// mixed control widths (date picker, time picker, input).
///
/// `cl_club_forms` has the same widget for its forms; the two packages
/// share no code.
class LabeledFormRow extends StatelessWidget {
  /// Labels [field] with [label], or with [labelChild].
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

  /// The field the label belongs to.
  final Widget field;

  /// Whether the field must be filled; marks a plain [label].
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
      spacing: FormSpacing.labelGap,
      children: [
        Align(alignment: Alignment.centerLeft, child: labelWidget),
        field,
      ],
    );
  }
}
