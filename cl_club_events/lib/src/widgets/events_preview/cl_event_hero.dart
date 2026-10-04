import 'package:cl_member_auth/cl_member_auth.dart'
    show imageAuthHeadersProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show eventCoverImageProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show CredentialedNetworkImage, ThemedMarkdown;

import 'cl_event_stamps.dart';

/// Hero card — mirrors the user-profile `ProfileCard` layout:
/// * mobile (<700 px): image on top, description below;
/// * desktop (≥700 px): image on the left, description on the right.
///
/// Renders only the image (full-width strip) when the description is empty
/// so we don't leave an empty content panel.
class ClEventHeroCard extends StatelessWidget {
  const ClEventHeroCard({required this.event, super.key});

  final Event event;

  static const double _mobileBreakpoint = 700;
  static const double _desktopImageWidth = 320;
  static const double _mobileImageHeight = 240;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final hasDescription = event.description.isNotEmpty;
    final isMobile = MediaQuery.sizeOf(context).width < _mobileBreakpoint;

    final imageWidget = ClEventHero(event: event);
    final descriptionWidget = Padding(
      padding: const EdgeInsets.all(20),
      child: ThemedMarkdown(
        data: event.description,
        textAlign: TextAlign.left,
      ),
    );

    if (!hasDescription) {
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: _mobileImageHeight,
          width: double.infinity,
          child: imageWidget,
        ),
      );
    }

    if (isMobile) {
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: _mobileImageHeight, child: imageWidget),
            descriptionWidget,
          ],
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 260),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: _desktopImageWidth, child: imageWidget),
            Expanded(child: descriptionWidget),
          ],
        ),
      ),
    );
  }
}

/// Image-only strip with cover image (or muted placeholder) and the
/// stamps cluster overlaid bottom-right. Used inside [ClEventHeroCard].
class ClEventHero extends StatelessWidget {
  const ClEventHero({required this.event, super.key});

  final Event event;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: ClEventCover(event: event)),
        Positioned(
          right: 12,
          bottom: 12,
          child: ClEventStamps(event: event),
        ),
      ],
    );
  }
}

/// Cover image area for an event, with a centered icon placeholder when
/// no cover is set or the image fails to load.
///
/// The cover is resolved from the v2 media link table (`event_cover` tag) via
/// [eventCoverImageProvider] and rendered through [CredentialedNetworkImage]
/// with bearer headers.
class ClEventCover extends ConsumerWidget {
  const ClEventCover({required this.event, super.key});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final bg = theme.colorScheme.muted;
    final fg = theme.colorScheme.mutedForeground;

    final coverUrl = ref.watch(eventCoverImageProvider(event.id)).valueOrNull;
    final headers = ref.watch(imageAuthHeadersProvider).valueOrNull ?? const {};
    if (coverUrl == null) {
      return EventCoverPlaceholder(bg: bg, fg: fg);
    }
    return ColoredBox(
      color: bg,
      child: CredentialedNetworkImage(
        imageUrl: coverUrl,
        httpHeaders: headers,
        fit: BoxFit.cover,
        errorBuilder: (_) => EventCoverPlaceholder(bg: bg, fg: fg),
      ),
    );
  }
}

class EventCoverPlaceholder extends StatelessWidget {
  const EventCoverPlaceholder({required this.bg, required this.fg, super.key});

  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: bg,
      child: Center(
        child: Icon(LucideIcons.calendarDays, size: 72, color: fg),
      ),
    );
  }
}
