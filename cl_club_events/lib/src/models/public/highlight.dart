import 'highlight_type.dart';

/// One item of the landing page's highlight carousel.
///
/// Featured events today (`EventHighlight`); the interface exists so other
/// kinds of thing — news, an offer — can join them without the carousel
/// learning about events. Where a highlight leads is the host's to decide:
/// it carries its [id] and [type], never a route.
abstract interface class Highlight {
  /// Unique identifier; for an event, its public id.
  String get id;

  /// Kind of highlight.
  HighlightType get type;

  /// Main title.
  String get title;

  /// Secondary text (tagline, summary, …).
  String get subtitle;

  /// Optional image URL.
  String? get imageUrl;

  /// Optional eye-catching badge text (e.g. "Christmas Camp!").
  String? get stamp;

  /// Whether this should be displayed as the featured (large) item.
  bool get isFeatured;
}
