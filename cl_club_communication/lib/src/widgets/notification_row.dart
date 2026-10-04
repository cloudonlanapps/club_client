import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ThemedMarkdown;

import '../utils/notification_formatter.dart';
import '../utils/notification_registry.dart' show notificationTypeLabel;

/// One row in the Notifications / Pending Actions surfaces.
///
/// Renders the `NotificationDisplay` produced by [formatNotification] —
/// icon + body + `~Label` muted subtitle — plus a relative timestamp and an
/// unread-dot indicator. Tap is delegated; the row itself has no mutation
/// behavior.
///
/// The body is **markdown** (rendered via [ThemedMarkdown]) so broadcast
/// announcements composed with the markdown editor render the same `**bold**`,
/// lists and links in-app as they do in email (#740). Server-generated bodies
/// are plain prose that renders identically through markdown. The body is
/// rendered in a normal weight (not bolded for unread rows) so its own
/// markdown emphasis is preserved; the unread dot carries the unread signal.
/// A body that actually overflows ~2 lines is clamped with a "Show more" /
/// "Show less" toggle that expands it in place; a body that already fits shows
/// no toggle (overflow is measured, not guessed from length). When the kind's
/// `typeLabel` is null/empty (e.g. `user.registration_pending` after #381 — the
/// body already names the user), the subtitle line is omitted entirely.
class NotificationRow extends StatefulWidget {
  const NotificationRow({
    required this.notification,
    this.onTap,
    this.trailing,
    super.key,
  });

  final AppNotification notification;
  final VoidCallback? onTap;

  /// Optional widget to show on the right (e.g., action buttons for the
  /// Pending Actions list). When null, only the unread dot is rendered.
  final Widget? trailing;

  /// Height of the collapsed (~2 line) body preview, in logical pixels. The
  /// toggle appears only when the body's natural height exceeds this.
  static const double _collapsedBodyHeight = 44;

  @override
  State<NotificationRow> createState() => _NotificationRowState();
}

class _NotificationRowState extends State<NotificationRow> {
  bool _expanded = false;

  /// Natural (unclipped) height of the markdown body, measured after layout.
  /// Null until the first measurement; the toggle stays hidden until we know
  /// the body actually overflows the collapsed window.
  double? _bodyHeight;

  @override
  Widget build(BuildContext context) {
    final display = formatNotification(widget.notification);
    final theme = ShadTheme.of(context);
    final isUnread = !widget.notification.isRead;
    final label = notificationTypeLabel(widget.notification.type);
    final showSubtitle = label.isNotEmpty;

    // Markdown owns its own emphasis — do not force-bold the whole body for
    // unread rows (that would flatten `**bold**` into "everything bold"). The
    // unread dot is the unread affordance.
    final bodyStyle = theme.textTheme.small;

    // Measure the body's natural height so the toggle shows only on real
    // overflow. The measured child always lays out unclipped (the collapse
    // wrapper below uses an unbounded OverflowBox), so the measurement is the
    // same whether collapsed or expanded.
    final measured = _MeasureHeight(
      onChange: (h) {
        if (h != _bodyHeight) setState(() => _bodyHeight = h);
      },
      child: ThemedMarkdown(
        data: display.body,
        textAlign: TextAlign.left,
        textStyle: bodyStyle,
        // Inside a tappable row: don't let SelectionArea swallow the row tap.
        selectable: false,
      ),
    );

    final isLong =
        _bodyHeight != null &&
        _bodyHeight! > NotificationRow._collapsedBodyHeight + 1;

    Widget body = measured;
    if (isLong && !_expanded) {
      // Clip to ~2 lines. OverflowBox lets the markdown lay out at its natural
      // height (so its internal Column isn't force-fit into the clamp and
      // doesn't report an overflow) while ClipRect trims it to the preview
      // height.
      body = SizedBox(
        height: NotificationRow._collapsedBodyHeight,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minHeight: 0,
            maxHeight: double.infinity,
            child: body,
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              display.icon,
              size: 18,
              color: theme.colorScheme.mutedForeground,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: body),
                      const SizedBox(width: 8),
                      Text(
                        _relativeTime(widget.notification.createdAtUtc),
                        style: theme.textTheme.muted.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                  if (isLong)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ShadButton.link(
                        size: ShadButtonSize.sm,
                        padding: EdgeInsets.zero,
                        onPressed: () => setState(() => _expanded = !_expanded),
                        child: Text(_expanded ? 'Show less' : 'Show more'),
                      ),
                    ),
                  if (showSubtitle) ...[
                    const SizedBox(height: 2),
                    Text(
                      '~$label',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.muted.copyWith(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (widget.trailing != null)
              widget.trailing!
            else if (isUnread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _relativeTime(DateTime utc) {
  final now = DateTime.now().toUtc();
  final diff = now.difference(utc);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return DateFormat.MMMd().format(utc.toLocal());
}

/// Reports its child's laid-out height via [onChange] after each layout (in a
/// post-frame callback, so a `setState` in the callback is safe). Used to
/// decide whether the markdown body actually overflows the collapsed window —
/// a length heuristic can't know the rendered height, so a short two-line body
/// never gets a spurious "Show more".
class _MeasureHeight extends SingleChildRenderObjectWidget {
  const _MeasureHeight({required this.onChange, required Widget super.child});

  final ValueChanged<double> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _MeasureHeightRender(onChange);

  @override
  void updateRenderObject(
    BuildContext context,
    _MeasureHeightRender renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}

class _MeasureHeightRender extends RenderProxyBox {
  _MeasureHeightRender(this.onChange);

  ValueChanged<double> onChange;
  double? _lastReported;

  @override
  void performLayout() {
    super.performLayout();
    final height = child?.size.height ?? 0;
    if (height == _lastReported) return;
    _lastReported = height;
    WidgetsBinding.instance.addPostFrameCallback((_) => onChange(height));
  }
}
