import 'package:meta/meta.dart';

@immutable
class EventDetailFacilitiesLabels {
  const EventDetailFacilitiesLabels({required this.title});

  final String title;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventDetailFacilitiesLabels && other.title == title;
  }

  @override
  int get hashCode => title.hashCode;
}
