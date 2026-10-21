import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Shared "first row" for every routed screen inside `/memberzone`.
///
/// Renders a single-line strip with:
///
/// * an optional back button (rendered iff [onBack] is non-null),
/// * a [title] string, and
/// * an optional [subtitle] rendered on the row below as muted secondary text.
///
/// `ui_lib` is deliberately router-free, so back navigation is driven by the
/// host via [onBack] rather than a raw `Navigator` here. The host decides
/// whether the route is poppable and supplies `null` to hide the button.
///
/// The trailing slot is reserved for **two** sanctioned affordances: an
/// optional Broadcast button ([onBroadcast], club_client#252) and an
/// optional audit-history button ([onHistory], issue #207). Issue #252's rule
/// (club_core's) still holds for everything else — pencil edit affordances,
/// kebab menus, bulk-action buttons, status indicators, and save commits all
/// live in the body of the screen, never here. Broadcast and History are the
/// exceptions because each is pure navigation (a callback) to another
/// screen, not an action on the entity, and the host supplies `null` to hide
/// it for viewers who may not use it.
class TitleRow extends StatelessWidget {
  const TitleRow({
    required this.title,
    this.subtitle,
    this.onBack,
    this.onBroadcast,
    this.onHistory,
    super.key,
  });

  final String title;
  final String? subtitle;

  /// Invoked when the back button is pressed. When `null`, no back button is
  /// rendered (the leading slot stays reserved so title alignment is stable).
  final VoidCallback? onBack;

  /// Opens the Broadcast screen for this page's audience (a group, an event,
  /// a member), club_client#252. When `null` (the default, and every viewer
  /// who may not broadcast) no button renders. The host passes a callback
  /// only for admins.
  final VoidCallback? onBroadcast;

  /// Invoked when the audit-history button is pressed. When `null` (the
  /// default, and every viewer who may not see history), no button renders
  /// and the trailing slot collapses. The host decides visibility — it passes
  /// a callback only for admins (see issue #207).
  final VoidCallback? onHistory;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    // Reserve a fixed-width leading slot so the title's horizontal position
    // is identical whether or not the back button is rendered.
    const leadingWidth = 48.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 24, 4),
      child: Row(
        children: [
          SizedBox(
            width: leadingWidth,
            height: leadingWidth,
            child: onBack != null
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, size: 20),
                    tooltip: 'Back',
                    onPressed: onBack,
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.h3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(
                    subtitle!,
                    style: theme.textTheme.muted,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
              ],
            ),
          ),
          if (onBroadcast != null)
            IconButton(
              icon: const Icon(LucideIcons.messageSquare, size: 20),
              tooltip: 'Broadcast',
              onPressed: onBroadcast,
            ),
          if (onHistory != null)
            IconButton(
              icon: const Icon(Icons.history, size: 20),
              tooltip: 'History',
              onPressed: onHistory,
            ),
        ],
      ),
    );
  }
}
