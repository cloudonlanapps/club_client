import 'package:flutter/material.dart'
    show
        CircularProgressIndicator,
        PopupMenuButton,
        PopupMenuItem,
        PopupMenuPosition;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/cards/entity_card.dart' show EntityCard;
import 'package:ui_lib/ui_lib.dart' show EntityCard;

import '../action_button.dart';
import 'action_item.dart';

/// Renders a small set of [ActionItem]s as the trailing action area of an
/// [EntityCard]. Up to [inlineLimit] actions render inline; any additional
/// actions collapse behind a vertical-ellipsis overflow menu.
///
/// Empty action lists render `SizedBox.shrink()` — the surrounding card simply
/// reserves no trailing slot.
class ActionGroup extends StatelessWidget {
  const ActionGroup({
    required this.actions,
    this.inlineLimit = 2,
    super.key,
  });

  final List<ActionItem> actions;
  final int inlineLimit;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    final inlineCount = actions.length <= inlineLimit ? actions.length : 1;
    final inline = actions.take(inlineCount).toList();
    final overflow = actions.skip(inlineCount).toList();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < inline.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          if (inline[i].showsReason) ...[
            inline[i].reason!(context),
            const SizedBox(width: 4),
          ],
          InlineActionButton(item: inline[i]),
        ],
        if (overflow.isNotEmpty) ...[
          const SizedBox(width: 4),
          OverflowActionMenu(items: overflow),
        ],
      ],
    );
  }
}

/// A single inline action button. Owns the popover controller when the
/// underlying [ActionItem.popover] is non-null.
class InlineActionButton extends StatefulWidget {
  const InlineActionButton({required this.item, super.key});

  final ActionItem item;

  @override
  State<InlineActionButton> createState() => InlineActionButtonState();
}

class InlineActionButtonState extends State<InlineActionButton> {
  ShadPopoverController? controller;

  @override
  void initState() {
    super.initState();
    if (widget.item.popover != null) {
      controller = ShadPopoverController();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.item.popover != null && controller != null) {
      return ShadPopover(
        controller: controller,
        popover: widget.item.popover!,
        child: ActionButton(
          label: widget.item.label,
          loading: widget.item.loading,
          onPressed: widget.item.loading ? null : controller!.toggle,
        ),
      );
    }
    return ActionButton(
      label: widget.item.label,
      loading: widget.item.loading,
      onPressed: widget.item.onPressed,
    );
  }
}

/// Vertical-ellipsis overflow menu for actions beyond the inline limit.
class OverflowActionMenu extends StatelessWidget {
  const OverflowActionMenu({required this.items, super.key});

  final List<ActionItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return PopupMenuButton<int>(
      icon: Icon(
        LucideIcons.ellipsisVertical,
        size: 16,
        color: theme.colorScheme.mutedForeground,
      ),
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 4),
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 220),
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
                if (items[i].showsReason) ...[
                  const SizedBox(width: 8),
                  items[i].reason!(context),
                ],
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
