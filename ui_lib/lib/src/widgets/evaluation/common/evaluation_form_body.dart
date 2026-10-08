import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/form_spacing.dart';

/// The body of an evaluation form: its rows stacked with the row gap and,
/// under them, the form-level [error] a rule across fields or the server
/// raised.
///
/// Sits inside the form's `ShadForm`. With [error] null nothing shows under
/// the rows. (`cl_club_forms` has the same widget for its forms; the two
/// packages share no code.)
class EvaluationFormBody extends StatelessWidget {
  /// Stacks [children], with [error] under them.
  const EvaluationFormBody({required this.children, this.error, super.key});

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
