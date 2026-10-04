import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../theme/text_theme_extensions.dart';

/// Standardized outline action button used across the app.
///
/// Provides consistent sizing (`ShadButtonSize.sm`), text style
/// (`buttonLabel` — 11px, w500), and optional loading spinner.
///
/// ```dart
/// ActionButton(
///   label: 'Accept',
///   onPressed: () => handleAccept(),
///   loading: isLoading,
/// )
/// ```
class ActionButton extends StatelessWidget {
  const ActionButton({
    required this.label,
    this.onPressed,
    this.enabled = true,
    this.loading = false,
    this.child,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool loading;

  /// Optional custom child. When provided, replaces the default label text.
  /// The loading spinner still takes precedence when [loading] is true.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return ShadButton.outline(
      size: ShadButtonSize.sm,
      enabled: enabled && !loading,
      onPressed: enabled && !loading ? onPressed : null,
      child: loading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : child ?? Text(label, style: theme.textTheme.buttonLabel),
    );
  }
}
