import 'package:flutter/foundation.dart';
import 'package:ui_lib/ui_lib.dart' show PageData;

import 'detail_labels/event_detail_labels.dart';

/// An event page's copy: the page around the event and its section labels.
///
/// The host builds it from its own text: the website from its copy, the
/// member app's marketing preview from the defaults.
@immutable
class EventDetailPageData {
  const EventDetailPageData({required this.pageData, required this.labels});

  /// The page: the hero (the event's stamp, title and short description),
  /// the empty state and the CTA for the event's state.
  final PageData pageData;

  /// The event's section labels (about, highlights, fees, etc.).
  final EventDetailLabels labels;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventDetailPageData &&
        other.pageData == pageData &&
        other.labels == labels;
  }

  @override
  int get hashCode => Object.hash(pageData, labels);
}
