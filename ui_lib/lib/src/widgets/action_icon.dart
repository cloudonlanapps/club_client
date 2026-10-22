import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/action_button.dart' show ActionButton;

/// Standardized icon-only action button used across the app.
///
/// Provides consistent sizing (`ShadButtonSize.sm`, 20px icon),
/// optional color tinting, and a loading spinner.
///
/// Pairs with [ActionButton] for icon-only contexts (e.g., approve/reject
/// icons in compact list rows, or the narrow-screen form of a header
/// action).
///
/// [label] names the action: assistive technology announces it for the
/// button, since the icon carries no words. Where an [ActionButton] stands
/// in its place on a wide screen, pass that button's label, so the action
/// has one name in both layouts.
///
/// ```dart
/// ActionIcon(
///   icon: Icons.check,
///   label: 'Approve',
///   color: theme.colorScheme.primary,
///   onPressed: () => handleApprove(),
///   loading: isLoading,
/// )
/// ```
class ActionIcon extends StatelessWidget {
  const ActionIcon({
    required this.icon,
    required this.label,
    this.onPressed,
    this.enabled = true,
    this.loading = false,
    this.color,
    this.size = 20,
    super.key,
  });

  final IconData icon;

  /// The action's name, announced in place of the icon.
  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool loading;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: ShadButton.ghost(
        size: ShadButtonSize.sm,
        enabled: enabled && !loading,
        onPressed: enabled && !loading ? onPressed : null,
        child: loading
            ? SizedBox(
                width: size,
                height: size,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, color: color, size: size),
      ),
    );
  }
}
