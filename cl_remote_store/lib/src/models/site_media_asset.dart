import 'package:meta/meta.dart';

/// What fills a website media slot: where the media is, and what it is
/// (club_core#53).
///
/// The type travels with the URI rather than being read off it. The server
/// says what a file is (club_server#424); a renderer that decides from the
/// URL is guessing, and a hero that guesses wrong renders nothing.
@immutable
class SiteMediaAsset {
  const SiteMediaAsset({
    required this.uri,
    required this.isVideo,
    this.previewUri,
  });

  final String uri;
  final bool isVideo;

  /// What to show where a video cannot play inline: the server's animated
  /// preview where it made one, else its still frame, else `null` — and then
  /// the caller's own default.
  ///
  /// Never derived from [uri]: the preview lives at the same address under
  /// `?variant=`, and a derived path 404s.
  final String? previewUri;

  SiteMediaAsset copyWith({
    String? uri,
    bool? isVideo,
    String? Function()? previewUri,
  }) {
    return SiteMediaAsset(
      uri: uri ?? this.uri,
      isVideo: isVideo ?? this.isVideo,
      previewUri: previewUri != null ? previewUri() : this.previewUri,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SiteMediaAsset &&
          other.uri == uri &&
          other.isVideo == isVideo &&
          other.previewUri == previewUri;

  @override
  int get hashCode => Object.hash(uri, isVideo, previewUri);

  @override
  String toString() =>
      'SiteMediaAsset(uri: $uri, isVideo: $isVideo, previewUri: $previewUri)';
}
