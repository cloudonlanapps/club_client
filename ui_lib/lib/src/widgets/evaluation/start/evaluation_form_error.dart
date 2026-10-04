import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// A form-level message under an evaluation form, in the destructive
/// colour of the theme's small text.
class EvaluationFormError extends StatelessWidget {
  /// Shows [message].
  const EvaluationFormError({required this.message, super.key});

  /// The message.
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Text(
      message,
      style: theme.textTheme.small.copyWith(
        color: theme.colorScheme.destructive,
      ),
    );
  }
}
