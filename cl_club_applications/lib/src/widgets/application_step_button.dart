import 'package:flutter/widgets.dart';
import 'package:ui_lib/ui_lib.dart' show ActionButton;

import '../models/application_step.dart';

/// One move of the heading card: an [ActionButton], greyed out while it
/// may not run ([enabled]), where the card says why (the Missing and
/// Unknown facts lists).
class ApplicationStepButton extends StatelessWidget {
  const ApplicationStepButton({
    required this.step,
    required this.onPressed,
    this.enabled = true,
    this.loading = false,
    super.key,
  });

  /// The move.
  final ApplicationStep step;

  /// Runs it; null while another move runs.
  final VoidCallback? onPressed;

  /// Whether it may run now.
  final bool enabled;

  /// Whether it is running.
  final bool loading;

  @override
  Widget build(BuildContext context) => ActionButton(
    key: ValueKey('application.step.${step.name}'),
    label: step.label,
    loading: loading,
    enabled: enabled,
    onPressed: onPressed,
  );
}
