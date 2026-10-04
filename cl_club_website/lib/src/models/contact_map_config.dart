/// Embed configuration for the Contact Us map widget.
///
/// The [mapUri] follows the format documented on `MapEmbed`: either
/// `"<embedUrl>"` or `"<embedUrl>|<linkUrl>"`. [fallbackTitle] is shown on
/// platforms/browsers that can't render the Google Maps iframe and fall back
/// to a link-only card.
class ContactMapConfig {
  const ContactMapConfig({required this.mapUri, this.fallbackTitle});

  final String mapUri;
  final String? fallbackTitle;

  bool get hasEmbed => mapUri.isNotEmpty;
}
