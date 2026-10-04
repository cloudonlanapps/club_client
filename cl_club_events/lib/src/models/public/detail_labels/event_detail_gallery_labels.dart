import 'package:meta/meta.dart';

@immutable
class EventDetailGalleryLabels {
  const EventDetailGalleryLabels({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventDetailGalleryLabels &&
        other.title == title &&
        other.subtitle == subtitle;
  }

  @override
  int get hashCode => Object.hash(title, subtitle);
}
