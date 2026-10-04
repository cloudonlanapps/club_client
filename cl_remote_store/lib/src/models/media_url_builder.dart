import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:meta/meta.dart';

/// Turns media descriptors into download URLs against one API base
/// (club_core#53).
///
/// The server does not send image URLs. Anything it owns — a coach's avatar,
/// a venue photo, an event cover, a gallery item, a site media slot — arrives
/// as a [MediaRef]: the uuid, what the file is, what to call it, and which
/// previews exist for it. The URL shape is the SDK's; this only binds it to
/// the API base.
@immutable
class MediaUrlBuilder {
  const MediaUrlBuilder(this.apiBaseUrl);

  final String apiBaseUrl;

  /// The download URL for [media], or `null` when there is no media.
  ///
  /// Returning null rather than a broken URL lets a caller choose its own
  /// placeholder.
  String? call(MediaRef? media) =>
      media == null ? null : mediaDownloadUrl(apiBaseUrl, media);

  /// The still preview for [media]: a video's frame, a PDF's first page.
  ///
  /// `null` for an image, which is its own preview, and `null` for no media.
  /// Never a derived `..._poster.webp` path: the server keeps a preview at the
  /// same address under `?variant=`, and the derived one 404s.
  String? preview(MediaRef? media) =>
      media == null ? null : mediaPosterUrl(apiBaseUrl, media);

  /// The animated preview for [media], or `null` where there is none.
  String? animated(MediaRef? media) =>
      media == null ? null : mediaAnimatedUrl(apiBaseUrl, media);

  @override
  bool operator ==(Object other) =>
      other is MediaUrlBuilder && other.apiBaseUrl == apiBaseUrl;

  @override
  int get hashCode => apiBaseUrl.hashCode;

  @override
  String toString() => 'MediaUrlBuilder(apiBaseUrl: $apiBaseUrl)';
}
