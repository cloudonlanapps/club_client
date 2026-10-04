import 'dart:async';

import 'package:cl_gallery_viewer/cl_gallery_viewer.dart'
    show
        GalleryItem,
        MediaConversionStatus,
        MediaKind,
        MediaUploadRequest,
        MediaUploadResult,
        MediaUploader,
        MediaUploaderMode;
import 'package:cl_member_auth/cl_member_auth.dart'
    show imageAuthHeadersProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        EventGalleryImage,
        eventGalleryProvider,
        eventMediaMutationProvider,
        mediaDownloadUrlProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show Media;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show
        CircleIconButton,
        CredentialedNetworkImage,
        SectionEditButton,
        openPdfDownload;

import 'gallery_display.dart';

/// Connected event gallery for the event detail view.
///
/// By default it renders the read viewer — `cl_gallery_viewer`'s
/// [GalleryDisplay], fed mixed-media (`image` / `video` / `pdf`) items resolved
/// from [eventGalleryProvider], which lists **only** the event's
/// `event_gallery`-tagged links (not every media the event touches).
///
/// When [canEdit], an edit pencil swaps the viewer in-place for a manage grid:
/// multi-file add via `cl_gallery_viewer`'s [MediaUploader] (video-aware,
/// conversion-status polled) plus a per-tile remove. Edit rights mirror the
/// server, which gates event-media writes with `require_admin_or_coach` — so a
/// coach passes `canEdit: true` even on the otherwise read-only preview body.
class ClEventGallery extends ConsumerStatefulWidget {
  const ClEventGallery({
    required this.eventId,
    required this.canEdit,
    super.key,
  });

  final int eventId;
  final bool canEdit;

  @override
  ConsumerState<ClEventGallery> createState() => _ClEventGalleryState();
}

class _ClEventGalleryState extends ConsumerState<ClEventGallery> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final images =
        ref.watch(eventGalleryProvider(widget.eventId)).valueOrNull ??
        const <EventGalleryImage>[];

    // A read-only viewer has nothing to show or add when empty — hide the
    // whole section (also covers the error case: the provider coalesces to an
    // empty list, so a gallery fetch failure never breaks the event page).
    if (images.isEmpty && !widget.canEdit) return const SizedBox.shrink();

    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Gallery', style: theme.textTheme.h4),
              const Spacer(),
              if (widget.canEdit && _editing)
                ShadButton.ghost(
                  onPressed: () => setState(() => _editing = false),
                  child: const Text('Done'),
                )
              else if (widget.canEdit)
                SectionEditButton(
                  onTap: () => setState(() => _editing = true),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_editing)
            _buildEditGrid(images)
          else if (images.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No gallery media yet. Tap the pencil to add photos, '
                'videos, or PDFs.',
                style: theme.textTheme.muted,
              ),
            )
          else
            GalleryDisplay(
              items: [for (final img in images) _toGalleryItem(img)],
              isMobile: isMobile,
              onPdfDownload: _handlePdfDownload,
            ),
        ],
      ),
    );
  }

  Widget _buildEditGrid(List<EventGalleryImage> images) {
    final uploading = ref
        .watch(eventMediaMutationProvider(widget.eventId))
        .isLoading;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final img in images)
          GalleryTile(
            url: img.url,
            mediaType: img.mediaType,
            onRemove: uploading ? null : () => _remove(img.mediaUuid),
          ),
        MediaUploader(
          // allowedKinds defaults to {image, video, pdf} — mixed media.
          mode: MediaUploaderMode.multi,
          uploadCallback: _upload,
          statusCallback: _status,
          onComplete: _onComplete,
          triggerBuilder: (context, openPicker) => GalleryAddTile(
            busy: uploading,
            onTap: uploading ? null : openPicker,
          ),
        ),
      ],
    );
  }

  // --- Upload flow (SDK calls live on the master notifier) ---

  Future<MediaUploadResult> _upload(MediaUploadRequest req) async {
    final media = await ref
        .read(eventMediaMutationProvider(widget.eventId).notifier)
        .uploadGalleryMedia(
          bytes: req.bytes,
          filename: req.filename,
          contentType: req.mimeType,
        );
    return _toResult(media);
  }

  Future<MediaUploadResult> _status(int id) async {
    final media = await ref
        .read(eventMediaMutationProvider(widget.eventId).notifier)
        .galleryMediaStatus(id);
    return _toResult(media);
  }

  /// Attach each completed upload to the event's gallery. The uploader fires
  /// this without awaiting, so failures are surfaced via a toast here rather
  /// than propagated.
  Future<void> _onComplete(List<MediaUploadResult> results) async {
    for (final result in results) {
      try {
        await ref
            .read(eventMediaMutationProvider(widget.eventId).notifier)
            .attachGalleryMedia(result.uuid);
      } on Object catch (_) {
        if (!mounted) return;
        ShadToaster.of(context).show(
          const ShadToast.destructive(
            description: Text('Could not add some media. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> _remove(String mediaUuid) async {
    try {
      await ref
          .read(eventMediaMutationProvider(widget.eventId).notifier)
          .removeGalleryImage(mediaUuid);
    } on Object catch (_) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          description: Text('Could not remove media. Please try again.'),
        ),
      );
    }
  }

  MediaUploadResult _toResult(Media media) => MediaUploadResult(
    id: media.id,
    uuid: media.uuid,
    kind: _mediaKind(media.mediaType),
    status: _conversionStatus(media.conversionStatus),
    downloadUrl: ref.read(
      mediaDownloadUrlProvider((uuid: media.uuid, variant: 'original')),
    ),
  );

  GalleryItem _toGalleryItem(EventGalleryImage img) => switch (img.mediaType) {
    'video' => GalleryItem.video(
      img.url,
      id: img.mediaUuid,
      previewUrl: img.previewUrl,
    ),
    'pdf' => GalleryItem.pdf(
      img.url,
      id: img.mediaUuid,
      previewUrl: img.previewUrl,
    ),
    _ => GalleryItem.image(img.url, id: img.mediaUuid, previewUrl: null),
  };

  /// Opens the PDF at its API download URL. Event-gallery media is uploaded
  /// `public`, so the server serves it without the app's bearer token.
  void _handlePdfDownload(String pdfUrl) => unawaited(openPdfDownload(pdfUrl));
}

MediaKind _mediaKind(String mediaType) => switch (mediaType) {
  'video' => MediaKind.video,
  'pdf' => MediaKind.pdf,
  _ => MediaKind.image,
};

MediaConversionStatus _conversionStatus(String status) => switch (status) {
  'completed' => MediaConversionStatus.completed,
  'failed' => MediaConversionStatus.failed,
  'processing' => MediaConversionStatus.processing,
  _ => MediaConversionStatus.pending,
};

const double _kGalleryTile = 96;

/// One gallery thumbnail (image) or a typed placeholder (video / pdf) with a
/// remove (X) button overlaid top-right while editing.
class GalleryTile extends StatelessWidget {
  const GalleryTile({
    required this.url,
    required this.mediaType,
    required this.onRemove,
    super.key,
  });

  final String url;
  final String mediaType;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final content = switch (mediaType) {
      'video' => const _IconThumb(icon: LucideIcons.video),
      'pdf' => const _IconThumb(icon: LucideIcons.fileText),
      _ => MediaThumb(url: url),
    };
    return SizedBox(
      width: _kGalleryTile,
      height: _kGalleryTile,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: content,
          ),
          if (onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: CircleIconButton(
                icon: LucideIcons.x,
                size: 28,
                onTap: onRemove,
              ),
            ),
        ],
      ),
    );
  }
}

/// The "add media" tile — a muted box with a plus icon (or spinner when busy).
class GalleryAddTile extends StatelessWidget {
  const GalleryAddTile({required this.busy, required this.onTap, super.key});

  final bool busy;

  /// Tap handler, or `null` to render the tile disabled.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: busy ? null : onTap,
      child: Container(
        width: _kGalleryTile,
        height: _kGalleryTile,
        decoration: BoxDecoration(
          color: theme.colorScheme.muted.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.border),
        ),
        alignment: Alignment.center,
        child: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(LucideIcons.plus, color: theme.colorScheme.mutedForeground),
      ),
    );
  }
}

/// A muted box with a centered icon, used for non-image gallery tiles.
class _IconThumb extends StatelessWidget {
  const _IconThumb({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ColoredBox(
      color: theme.colorScheme.muted,
      child: Center(
        child: Icon(icon, color: theme.colorScheme.mutedForeground),
      ),
    );
  }
}

/// A media thumbnail resolved through [CredentialedNetworkImage] with bearer
/// headers, with a muted icon placeholder on load failure.
class MediaThumb extends ConsumerWidget {
  const MediaThumb({required this.url, super.key});

  final String url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final headers = ref.watch(imageAuthHeadersProvider).valueOrNull ?? const {};
    return ColoredBox(
      color: theme.colorScheme.muted,
      child: CredentialedNetworkImage(
        imageUrl: url,
        httpHeaders: headers,
        fit: BoxFit.cover,
        errorBuilder: (_) => Center(
          child: Icon(
            LucideIcons.imageOff,
            color: theme.colorScheme.mutedForeground,
          ),
        ),
      ),
    );
  }
}
