import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Small bordered chip displaying a status label. Non-coloured: outlined in
/// `mutedForeground`, text in `mutedForeground`. The previous coloured-pill
/// variant has been retired (see CLAUDE.md UI rules).
///
/// Two constructor styles:
///   * `StatusBadge.status('active')` — derives label + icon from a dynamic
///     status string; used by callers that get the value at runtime.
///   * Named factories (`.active`, `.pending`, `.programme`, …) — used by
///     cards / forms that know the status at compile time.
class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.label, this.icon, super.key});

  /// Legacy entry point — derives label and icon from a status string.
  factory StatusBadge.status(String status) {
    final lower = status.toLowerCase();
    IconData? icon;
    if (lower == 'active' || lower == 'published') {
      icon = LucideIcons.check;
    } else if (lower == 'pending' || lower == 'saved') {
      icon = LucideIcons.clock;
    } else if (lower == 'blocked' || lower == 'cancelled') {
      icon = LucideIcons.ban;
    } else if (lower == 'completed') {
      icon = LucideIcons.check;
    } else if (lower == 'left') {
      icon = LucideIcons.logOut;
    }
    return StatusBadge(label: status, icon: icon);
  }

  factory StatusBadge.active() =>
      const StatusBadge(label: 'Active', icon: LucideIcons.check);
  factory StatusBadge.pending() =>
      const StatusBadge(label: 'Pending', icon: LucideIcons.clock);
  factory StatusBadge.blocked() =>
      const StatusBadge(label: 'Blocked', icon: LucideIcons.ban);
  factory StatusBadge.left() =>
      const StatusBadge(label: 'Left', icon: LucideIcons.logOut);
  factory StatusBadge.programme() => const StatusBadge(label: 'Programme');
  factory StatusBadge.camp() => const StatusBadge(label: 'Camp');
  factory StatusBadge.oneOff() => const StatusBadge(label: 'One-Off');

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final fg = theme.colorScheme.mutedForeground;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: fg),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
