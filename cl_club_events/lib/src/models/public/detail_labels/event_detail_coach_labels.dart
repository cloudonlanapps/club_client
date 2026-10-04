import 'package:meta/meta.dart';

@immutable
class EventDetailCoachLabels {
  const EventDetailCoachLabels({
    required this.labelActive,
    required this.labelPast,
  });

  final String labelActive;
  final String labelPast;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventDetailCoachLabels &&
        other.labelActive == labelActive &&
        other.labelPast == labelPast;
  }

  @override
  int get hashCode => Object.hash(labelActive, labelPast);
}
