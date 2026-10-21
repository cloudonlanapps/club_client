import 'package:flutter/widgets.dart';
import 'package:ui_lib/src/widgets/cards/action_group.dart' show ActionGroup;

/// Single action entry handed to [ActionGroup].
///
/// Either [onPressed] or [popover] should be provided. When [popover] is
/// non-null, tapping the action opens a popover instead of invoking
/// [onPressed].
class ActionItem {
  const ActionItem({
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.destructive = false,
    this.popover,
    this.reason,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool destructive;
  final WidgetBuilder? popover;

  /// Why the action is unavailable, shown beside it while it is disabled
  /// (neither [onPressed] nor [popover], not [loading]) — e.g. a credit
  /// count. Generic: the widget says what it likes; nothing here knows what
  /// it is about.
  final WidgetBuilder? reason;

  /// Whether the action can be used: it is not [loading] and has either
  /// [onPressed] or [popover].
  bool get isActionable => !loading && (onPressed != null || popover != null);

  /// Whether [reason] is shown: the action is disabled and has one.
  bool get showsReason =>
      reason != null && !loading && onPressed == null && popover == null;
}
