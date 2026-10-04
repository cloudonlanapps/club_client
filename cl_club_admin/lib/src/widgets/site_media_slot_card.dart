import 'package:club_sdk_2/club_sdk_2.dart' show MediaRef;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show EntityCard;

import 'site_media_thumbnail.dart';

/// One website media slot: its label and key, what fills it (or that the
/// site shows its bundled default), and Upload / Link existing / Clear.
///
/// [error] is the server's refusal of this slot, shown in place.
class SiteMediaSlotCard extends StatelessWidget {
  const SiteMediaSlotCard({
    required this.serverKey,
    required this.label,
    required this.media,
    required this.onUpload,
    required this.onLink,
    required this.onClear,
    this.busy = false,
    this.error,
    super.key,
  });

  final String serverKey;
  final String label;
  final MediaRef? media;
  final VoidCallback onUpload;
  final VoidCallback onLink;
  final VoidCallback onClear;

  /// Disables the actions while an upload or a save is in flight.
  final bool busy;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final item = media;
    final problem = error;
    final card = EntityCard(
      image: SiteMediaThumbnail(media: item),
      title: label,
      caption: serverKey,
      body: Text(
        item == null
            ? "Default — the site's bundled file"
            : '${item.mediaTypeWord} · ${item.uuid}',
        style: theme.textTheme.muted,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      // Three actions, all in view: an overflow menu would hide the two a
      // slot is mostly about.
      trailingAction: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          ShadButton.outline(
            key: ValueKey('siteMediaSlot.$serverKey.upload'),
            size: ShadButtonSize.sm,
            leading: const Icon(LucideIcons.upload, size: 14),
            onPressed: busy ? null : onUpload,
            child: const Text('Upload'),
          ),
          ShadButton.outline(
            key: ValueKey('siteMediaSlot.$serverKey.link'),
            size: ShadButtonSize.sm,
            leading: const Icon(LucideIcons.link, size: 14),
            onPressed: busy ? null : onLink,
            child: const Text('Link existing'),
          ),
          ShadButton.outline(
            key: ValueKey('siteMediaSlot.$serverKey.clear'),
            size: ShadButtonSize.sm,
            leading: const Icon(LucideIcons.x, size: 14),
            onPressed: busy || item == null ? null : onClear,
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    // The refusal sits under the card: the card's row is one line high.
    return Column(
      key: ValueKey('siteMediaSlot.$serverKey'),
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        card,
        if (problem != null)
          Text(
            problem,
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.destructive,
            ),
          ),
      ],
    );
  }
}
