import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ThemedMarkdown;

/// One row in the Broadcast panel's recent-list.
///
/// Shows the broadcast text (pulled from `payload['data']['text']`),
/// rendered as **markdown** so the admin sees the same `**bold**` / lists /
/// links the recipients get (#740) — not the raw syntax. Also shows the send
/// timestamp and a read/unread summary. Revoked broadcasts are struck through
/// and muted.
class BroadcastRow extends StatelessWidget {
  const BroadcastRow({
    required this.broadcast,
    this.onRevoke,
    super.key,
  });

  final Broadcast broadcast;

  /// Tap handler for the trailing revoke icon. When `null` (or the
  /// broadcast is already revoked) the icon is omitted.
  final VoidCallback? onRevoke;

  String get _text {
    final raw = broadcast.payload['data'];
    if (raw is Map) {
      // Current shape: { type: 'broadcast.text', data: { text } }.
      // Older test fixtures (s23_broadcasts_test) emit
      // { type: 'broadcast.message', data: { title } } — read both so
      // legacy rows still display something readable.
      final t = raw['text'];
      if (t is String && t.isNotEmpty) return t;
      final title = raw['title'];
      if (title is String && title.isNotEmpty) return title;
    }
    return '(no text)';
  }

  String get _counts {
    final read = broadcast.readCount;
    final unread = broadcast.unreadCount;
    final total = broadcast.recipientCount;
    if (read == null && unread == null) {
      return '$total recipient${total == 1 ? '' : 's'}';
    }
    return '${read ?? 0} read · ${unread ?? 0} unread · $total total';
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final revoked = broadcast.status == BroadcastStatus.revoked;
    final muted = theme.colorScheme.mutedForeground;
    final sentAt = DateFormat.MMMd().add_jm().format(
      broadcast.sentAtUtc.toLocal(),
    );
    final revokedSuffix = revoked ? ' · revoked' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.megaphone, size: 18, color: muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ThemedMarkdown(
                  data: _text,
                  textAlign: TextAlign.left,
                  // Not a tappable row, but selection is unnecessary here and
                  // a SelectionArea would interfere with the revoke button.
                  selectable: false,
                  textStyle: theme.textTheme.small.copyWith(
                    decoration: revoked
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: revoked ? muted : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$sentAt · $_counts$revokedSuffix',
                  style: theme.textTheme.muted.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          if (!revoked && onRevoke != null) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Revoke',
              icon: Icon(LucideIcons.x, size: 16, color: muted),
              onPressed: onRevoke,
              splashRadius: 18,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
            ),
          ],
        ],
      ),
    );
  }
}
