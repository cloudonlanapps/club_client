import 'package:club_sdk_2/club_sdk_2.dart' show EventType;

import 'highlight.dart';
import 'highlight_type.dart';
import 'public_event_view.dart';

/// A [PublicEventView] seen as a [Highlight].
///
/// Public because the landing carousel type-tests for it: an event highlight
/// gets the full event card, anything else the generic one.
class EventHighlight implements Highlight {
  const EventHighlight(this.view);

  final PublicEventView view;

  @override
  String get id => view.publicId;

  @override
  HighlightType get type =>
      view.type == EventType.camp ? HighlightType.camp : HighlightType.event;

  @override
  String get title => view.title;

  @override
  String get subtitle => view.tagline ?? '';

  @override
  String? get imageUrl => view.imageUri;

  @override
  String? get stamp => view.stamp;

  @override
  bool get isFeatured => view.isFeatured;
}
