import 'package:meta/meta.dart';

@immutable
class EventDetailBatchTimingsLabels {
  const EventDetailBatchTimingsLabels({
    required this.title,
    required this.batchHeader,
    required this.timeHeader,
    required this.sessionHeader,
    required this.detailsHeader,
  });

  final String title;
  final String batchHeader;
  final String timeHeader;
  final String sessionHeader;
  final String detailsHeader;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventDetailBatchTimingsLabels &&
        other.title == title &&
        other.batchHeader == batchHeader &&
        other.timeHeader == timeHeader &&
        other.sessionHeader == sessionHeader &&
        other.detailsHeader == detailsHeader;
  }

  @override
  int get hashCode =>
      Object.hash(title, batchHeader, timeHeader, sessionHeader, detailsHeader);
}
