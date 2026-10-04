import 'package:flutter/material.dart'
    show
        CircularProgressIndicator,
        PopupMenuButton,
        PopupMenuItem,
        PopupMenuPosition;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/constants/breakpoints.dart' show Breakpoints;
import 'package:ui_lib/src/widgets/cards/entity_image.dart' show EntityImage;
import 'package:ui_lib/ui_lib.dart' show EntityImage;

import 'action_group.dart';
import 'action_item.dart';

const double kCardRadius = 8;
const double kImageWidth = 64;

/// Width at or below which [EntityCard] switches to its mobile layout —
/// title/body in the top row and the primary action stacked as a full-width
/// row beneath. Aliases the workspace-wide [Breakpoints.mobileMaxWidth].
const double kEntityCardMobileBreakpoint = Breakpoints.mobileMaxWidth;

/// Shared parent for every list-row entity card.
///
/// Layout contract on desktop:
/// `[image][InfoColumn(title, caption?, body?)][trailing?]`.
/// On mobile (`maxWidth < kEntityCardMobileBreakpoint`):
///   * the row stays `[image][InfoColumn]` only,
///   * the trailing action area drops to a full-width row underneath the
///     info column.
///
/// Callers pass actions via one of two slots:
///   * [trailingActions] (typed) — preferred. The first action renders inline
///     on every viewport; the remaining actions collapse behind a `⋮` menu,
///     which is their one home on mobile and desktop alike.
///   * [trailingAction] (widget) — bespoke. Renders to the right on desktop
///     and as a stacked full-width row on mobile.
///
/// Image bleeds to the card's left edge with left-rounded corners that match
/// the card chrome. The card never uses Material widgets — tap is wired via
/// [GestureDetector] + [MouseRegion]. See `docs/cards_design.txt` for the
/// full design.
class EntityCard extends StatelessWidget {
  const EntityCard({
    required this.image,
    required this.title,
    this.caption,
    this.body,
    this.trailingAction,
    this.trailingActions,
    this.onTap,
    this.dense = false,
    this.muted = false,
    super.key,
  }) : assert(
         trailingAction == null || trailingActions == null,
         'EntityCard: pass either trailingAction (Widget) or trailingActions '
         '(List<ActionItem>), not both.',
       );

  /// Required leading content. Use [EntityImage.network] / `.initials` /
  /// `.placeholder` so every row in a list reserves the same left column.
  final Widget image;

  final String title;

  /// Optional single muted line under the title.
  final String? caption;

  /// Optional widget rendered below the caption — typically a `Row` or
  /// `Column` of meta facts the card wants to surface.
  final Widget? body;

  /// Bespoke trailing widget. On desktop it sits to the right of the info
  /// column. On mobile it stacks as a full-width row beneath the info
  /// column. The widget renders as-is.
  ///
  /// Prefer [trailingActions] when the trailing content is a list of
  /// [ActionItem]s — it gets primary-inline + overflow-menu treatment.
  final Widget? trailingAction;

  /// Typed action list. The first entry is the "primary" action and renders
  /// inline on every viewport. On mobile the remaining entries are exposed
  /// through a `⋮` overflow menu at the end of the primary action's row.
  final List<ActionItem>? trailingActions;

  /// Whole-card tap handler. `null` makes the card non-tappable.
  final VoidCallback? onTap;

  /// Smaller padding + 13px title — used by calendar contexts.
  final bool dense;

  /// Foreground text uses `mutedForeground` — used for terminal / past rows.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < kEntityCardMobileBreakpoint;
        return _buildCard(context, isMobile: isMobile);
      },
    );
  }

  Widget _buildCard(BuildContext context, {required bool isMobile}) {
    final theme = ShadTheme.of(context);
    final padding = dense
        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 12)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 12);

    final titleStyle = theme.textTheme.p.copyWith(
      fontSize: dense ? 13 : null,
      fontWeight: FontWeight.w600,
      color: muted ? theme.colorScheme.mutedForeground : null,
    );
    final captionStyle = theme.textTheme.muted;

    final infoColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: titleStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (caption != null && caption!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            caption!,
            style: captionStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (body != null) ...[
          const SizedBox(height: 4),
          DefaultTextStyle.merge(
            style: muted
                ? TextStyle(color: theme.colorScheme.mutedForeground)
                : const TextStyle(),
            child: body!,
          ),
        ],
      ],
    );

    final desktopTrailing = _desktopTrailing();
    final mobileTrailing = isMobile ? _mobileTrailing() : null;

    final topRowChildren = <Widget>[
      Expanded(child: infoColumn),
      if (!isMobile && desktopTrailing != null) ...[
        const SizedBox(width: 12),
        desktopTrailing,
      ],
    ];

    final rightColumn = Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: topRowChildren,
          ),
          if (mobileTrailing != null) ...[
            const SizedBox(height: 8),
            mobileTrailing,
          ],
        ],
      ),
    );

    final row = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: kImageWidth,
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(kCardRadius),
              ),
              child: image,
            ),
          ),
          Expanded(child: rightColumn),
        ],
      ),
    );

    return ShadCard(
      padding: EdgeInsets.zero,
      child: _wrapTappable(onTap: onTap, child: row),
    );
  }

  /// Trailing widget to render on desktop. `null` means no trailing slot.
  Widget? _desktopTrailing() {
    if (trailingActions != null && trailingActions!.isNotEmpty) {
      return ActionGroup(actions: trailingActions!);
    }
    return trailingAction;
  }

  /// Trailing content for the stacked mobile row. `null` means nothing to
  /// stack below the info column.
  Widget? _mobileTrailing() {
    final actions = trailingActions;
    if (actions != null && actions.isNotEmpty) {
      return MobilePrimaryActionRow(
        primary: actions.first,
        overflow: actions.skip(1).toList(),
      );
    }
    return trailingAction;
  }

  static Widget _wrapTappable({
    required VoidCallback? onTap,
    required Widget child,
  }) {
    if (onTap == null) return child;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: child,
      ),
    );
  }
}

/// Full-width row used as the mobile-stacked action area. Renders the
/// primary action as an `InlineActionButton` and, when there are more
/// actions, a trailing `⋮` button that lists them in a popup menu — the
/// only place secondary actions appear on mobile.
class MobilePrimaryActionRow extends StatelessWidget {
  const MobilePrimaryActionRow({
    required this.primary,
    required this.overflow,
    super.key,
  });

  final ActionItem primary;
  final List<ActionItem> overflow;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: InlineActionButton(item: primary)),
        if (overflow.isNotEmpty) ...[
          const SizedBox(width: 4),
          OverflowMenuButton(items: overflow),
        ],
      ],
    );
  }
}

/// Compact ⋮ button that opens a popup menu listing [items]. A near-clone
/// of `OverflowActionMenu` from action_group.dart but sized for the mobile
/// inline row.
class OverflowMenuButton extends StatelessWidget {
  const OverflowMenuButton({required this.items, super.key});

  final List<ActionItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return PopupMenuButton<int>(
      icon: Icon(
        LucideIcons.ellipsisVertical,
        size: 18,
        color: theme.colorScheme.mutedForeground,
      ),
      tooltip: 'More actions',
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 4),
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 240),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.colorScheme.border),
      ),
      color: theme.colorScheme.card,
      onSelected: (i) {
        final item = items[i];
        if (item.loading) return;
        item.onPressed?.call();
      },
      itemBuilder: (_) => [
        for (var i = 0; i < items.length; i++)
          PopupMenuItem<int>(
            value: i,
            height: 36,
            enabled: !items[i].loading && items[i].onPressed != null,
            child: Row(
              children: [
                if (items[i].icon != null) ...[
                  Icon(
                    items[i].icon,
                    size: 14,
                    color: items[i].destructive
                        ? theme.colorScheme.destructive
                        : theme.colorScheme.foreground,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  items[i].label,
                  style: TextStyle(
                    fontSize: 12,
                    color: items[i].destructive
                        ? theme.colorScheme.destructive
                        : theme.colorScheme.foreground,
                  ),
                ),
                if (items[i].loading) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
