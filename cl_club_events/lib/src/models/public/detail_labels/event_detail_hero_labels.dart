import 'package:meta/meta.dart';

@immutable
class EventDetailHeroLabels {
  const EventDetailHeroLabels({
    required this.datesLabel,
    required this.timingsLabel,
    required this.venueLabel,
    required this.eligibilityLabel,
  });

  final String datesLabel;
  final String timingsLabel;
  final String venueLabel;
  final String eligibilityLabel;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventDetailHeroLabels &&
        other.datesLabel == datesLabel &&
        other.timingsLabel == timingsLabel &&
        other.venueLabel == venueLabel &&
        other.eligibilityLabel == eligibilityLabel;
  }

  @override
  int get hashCode =>
      Object.hash(datesLabel, timingsLabel, venueLabel, eligibilityLabel);
}
