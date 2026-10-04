import 'package:meta/meta.dart';

@immutable
class EventDetailFeesLabels {
  const EventDetailFeesLabels({
    required this.title,
    required this.includesLabel,
  });

  final String title;
  final String includesLabel;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventDetailFeesLabels &&
        other.title == title &&
        other.includesLabel == includesLabel;
  }

  @override
  int get hashCode => Object.hash(title, includesLabel);
}
