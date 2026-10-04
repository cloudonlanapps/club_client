import 'package:flutter/material.dart';
import 'package:ui_lib/ui_lib.dart' show HighlightMediaOrchestrator;

import '../../models/public/public_event_view.dart';

/// The cover of a public event card, with nothing overlaid on it.
///
/// Does not size itself: the caller wraps it (`AspectRatio`, `SizedBox`, …)
/// so it behaves predictably in a `Column`, a `Row`, and inside
/// `IntrinsicHeight`.
///
/// - A static image paints through `DecorationImage`, which claims no
///   intrinsic height, so the desktop card can stretch it to the content's
///   height inside `IntrinsicHeight` (an `Image.network` would report the
///   source's pixel height and blow the card up).
/// - A video cover plays through `HighlightMediaOrchestrator`.
///
/// [borderRadius] rounds the corners that meet the card's edge: the top on a
/// phone, the left on a wide screen.
///
/// Build it only when [PublicEventView.imageUri] is non-null.
class PublicEventCardImage extends StatelessWidget {
  const PublicEventCardImage({
    required this.event,
    required this.borderRadius,
    super.key,
  });

  final PublicEventView event;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final imageUri = event.imageUri;
    assert(
      imageUri != null,
      'PublicEventCardImage should only be built when event.imageUri != null',
    );

    // A cover is usually a photo but may be a video, and the server says
    // which (club_server#424) — no probing, no guessing from the URL.
    if (event.cover?.isVideo ?? false) {
      return HighlightMediaOrchestrator(
        uri: imageUri!,
        borderRadius: borderRadius,
        previewUri: event.imagePreviewUri,
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(imageUri!),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
