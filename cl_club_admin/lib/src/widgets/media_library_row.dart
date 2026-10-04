import 'package:cl_remote_store/cl_remote_store.dart' show isPublicMedia;
import 'package:club_sdk_2/club_sdk_2.dart' show Media, MediaRef;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'site_media_thumbnail.dart';

/// One item of the media library: a thumbnail, its name and type, and Link
/// — enabled only for media any website visitor may fetch.
class MediaLibraryRow extends StatelessWidget {
  const MediaLibraryRow({
    required this.media,
    required this.onLink,
    super.key,
  });

  final Media media;
  final ValueChanged<MediaRef> onLink;

  /// The media as a slot names it.
  MediaRef get ref => MediaRef(
    uuid: media.uuid,
    mimeType: media.mimeType,
    filename: media.filename,
  );

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final public = isPublicMedia(media);
    return Row(
      spacing: 12,
      children: [
        SizedBox.square(
          dimension: 48,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SiteMediaThumbnail(media: public ? ref : null),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(media.originalFilename, overflow: TextOverflow.ellipsis),
              Text(
                public ? media.mediaType : '${media.mediaType} · Not public',
                style: theme.textTheme.muted,
              ),
            ],
          ),
        ),
        ShadButton.outline(
          key: ValueKey('mediaLibrary.${media.uuid}'),
          size: ShadButtonSize.sm,
          onPressed: public ? () => onLink(ref) : null,
          child: const Text('Link'),
        ),
      ],
    );
  }
}
