import 'package:cl_gallery_viewer/cl_gallery_viewer.dart' show GalleryItem;
import 'package:club_sdk_2/club_sdk_2.dart' show EventType;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ClubTextTheme;

import '../../../models/public/detail_labels/event_detail_gallery_labels.dart';
import '../../../models/public/public_event_view.dart';
import 'public_event_gallery_strip.dart';

/// A public event's gallery: photos, videos and PDFs in a scrolling strip
/// under a title. A programme's sits on a muted band.
class PublicEventGallerySection extends StatelessWidget {
  const PublicEventGallerySection({
    required this.event,
    required this.labels,
    super.key,
  });

  /// Narrower than this is laid out for a phone.
  static const double mobileBreakpoint = 768;

  final PublicEventView event;
  final EventDetailGalleryLabels labels;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < mobileBreakpoint;
    final isProgram = event.event.type == EventType.programme;

    // A gallery is a mixture — a camp's can be twelve photos and four videos,
    // and selection trials carry a PDF. The server says which each is, and
    // where its preview lives (club_server#424): a video's still and a PDF's
    // first page are variants of the same address, so neither can be derived
    // from the URL and both are passed in.
    final items = <GalleryItem>[
      for (final item in event.gallery)
        if (item.isVideo)
          GalleryItem.video(
            event.uriOf(item),
            previewUrl: event.previewUriOf(item),
          )
        else if (item.isPdf)
          GalleryItem.pdf(
            event.uriOf(item),
            previewUrl: event.previewUriOf(item),
          )
        else
          // An image is its own preview: nothing to fetch.
          GalleryItem.image(event.uriOf(item), previewUrl: null),
    ];
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 40 : 60),
      color: isProgram ? theme.colorScheme.muted.withValues(alpha: 0.3) : null,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 48),
            child: Column(
              children: [
                Text(
                  labels.title,
                  style: isProgram
                      ? theme.textTheme.sectionTitle(isMobile: isMobile)
                      : theme.textTheme.subsectionTitle(isMobile: isMobile),
                ),
                const SizedBox(height: 8),
                Text(labels.subtitle, style: theme.textTheme.muted),
              ],
            ),
          ),
          const SizedBox(height: 32),
          PublicEventGalleryStrip(items: items, isMobile: isMobile),
        ],
      ),
    );
  }
}
