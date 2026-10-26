import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ActionButton;

import '../constants/application_view_sizes.dart';
import '../models/application_step.dart';

/// One move of the State card: an [ActionButton], greyed out with its
/// [reason] beside it when the move is not allowed now.
class ApplicationStepButton extends StatelessWidget {
  const ApplicationStepButton({
    required this.step,
    required this.onPressed,
    this.reason,
    this.loading = false,
    super.key,
  });

  /// The move.
  final ApplicationStep step;

  /// Runs it; null while another move runs.
  final VoidCallback? onPressed;

  /// Why it is not allowed now; null when it is.
  final String? reason;

  /// Whether it is running.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final why = reason;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: ApplicationViewSizes.reasonGap,
      children: [
        ActionButton(
          key: ValueKey('application.step.${step.name}'),
          label: step.label,
          loading: loading,
          enabled: why == null,
          onPressed: onPressed,
        ),
        if (why != null)
          Text(why, style: ShadTheme.of(context).textTheme.muted),
      ],
    );
  }
}
