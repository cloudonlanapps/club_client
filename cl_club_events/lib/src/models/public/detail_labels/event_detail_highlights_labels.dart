import 'package:meta/meta.dart';

@immutable
class EventDetailHighlightsLabels {
  const EventDetailHighlightsLabels({
    required this.titleActive,
    required this.titlePast,
  });

  final String titleActive;
  final String titlePast;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventDetailHighlightsLabels &&
        other.titleActive == titleActive &&
        other.titlePast == titlePast;
  }

  @override
  int get hashCode => Object.hash(titleActive, titlePast);
}
