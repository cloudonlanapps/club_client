import 'package:meta/meta.dart';

@immutable
class EventDetailEligibilityLabels {
  const EventDetailEligibilityLabels({required this.title});

  final String title;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventDetailEligibilityLabels && other.title == title;
  }

  @override
  int get hashCode => title.hashCode;
}
