import 'package:cl_remote_store/cl_remote_store.dart'
    show mediaRefDownloadUrlProvider, mediaRefPosterUrlProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show MediaRef;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_lib/ui_lib.dart' show EntityImage;

/// The leading image of a site media row: the item itself for an image, its
/// poster for a video, and a plain square when nothing is set.
///
/// Slot media is public, so no auth headers are needed.
class SiteMediaThumbnail extends ConsumerWidget {
  const SiteMediaThumbnail({required this.media, super.key});

  final MediaRef? media;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = media;
    if (item == null) return EntityImage.placeholder();
    final url = item.isImage
        ? ref.watch(
            mediaRefDownloadUrlProvider((media: item, variant: 'original')),
          )
        : ref.watch(mediaRefPosterUrlProvider(item));
    return url == null ? EntityImage.placeholder() : EntityImage.network(url);
  }
}
