import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/form_spacing.dart';

/// The body of a form: its rows stacked with the row gap and, under them,
/// the form-level [error] a rule across fields or the server raised.
///
/// Sits inside the form's `ShadForm`. With [error] null nothing shows under
/// the rows.
class FormBody extends StatelessWidget {
  const FormBody({required this.children, this.error, super.key});

  /// The rows, top to bottom.
  final List<Widget> children;

  /// The form-level message; null when there is none.
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final message = error;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FormSpacing.rowGap,
      children: [
        ...children,
        if (message != null)
          Text(
            message,
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.destructive,
            ),
          ),
      ],
    );
  }
}
