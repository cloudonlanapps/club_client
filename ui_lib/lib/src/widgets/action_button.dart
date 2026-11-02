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
    this.fitLabel = false,
    this.leading,
    this.child,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool loading;

  /// Whether the label shrinks, ending in an ellipsis, when the button is
  /// given less width than it needs. Set it only where the button's width is
  /// bounded: a phone's action row, not a row that sizes to its children.
  final bool fitLabel;

  /// Drawn before the label, e.g. a small state icon. Hidden while
  /// [loading].
  final Widget? leading;

  /// Optional custom child. When provided, replaces the default label text.
  /// The loading spinner still takes precedence when [loading] is true.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    // A button with nothing to do is drawn disabled, not only one that is
    // loading or turned off (club_client#414).
    final active = enabled && !loading && onPressed != null;
    return ShadButton.outline(
      size: ShadButtonSize.sm,
      enabled: active,
      onPressed: active ? onPressed : null,
      leading: loading ? null : leading,
      child: loading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : child ??
                (fitLabel
                    ? Flexible(
                        child: Text(
                          label,
                          style: theme.textTheme.buttonLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    : Text(label, style: theme.textTheme.buttonLabel)),
    );
  }
}
