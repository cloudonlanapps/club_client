import 'package:meta/meta.dart';

@immutable
class EventDetailOffersLabels {
  const EventDetailOffersLabels({
    required this.title,
    required this.validUntilPrefix,
  });

  final String title;
  final String validUntilPrefix;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventDetailOffersLabels &&
        other.title == title &&
        other.validUntilPrefix == validUntilPrefix;
  }

  @override
  int get hashCode => Object.hash(title, validUntilPrefix);
}
