import 'package:cl_gallery_viewer/cl_gallery_viewer.dart' show GalleryItem;
import 'package:club_sdk_2/club_sdk_2.dart' show MediaRef;

/// Gallery items for evidence files, by their kind.
abstract final class EvaluationGalleryItems {
  /// [media] at [url] as a gallery item: a video or a PDF with its
  /// [previewUrl], else an image (its own preview).
  static GalleryItem of(MediaRef media, String url, String? previewUrl) {
    if (media.isVideo) {
      return GalleryItem.video(url, id: media.uuid, previewUrl: previewUrl);
    }
    if (media.isPdf) {
      return GalleryItem.pdf(url, id: media.uuid, previewUrl: previewUrl);
    }
    return GalleryItem.image(url, id: media.uuid, previewUrl: null);
  }
}
