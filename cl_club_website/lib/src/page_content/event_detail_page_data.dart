import 'package:cl_club_events/cl_club_events.dart' show EventDetailLabels;
import 'package:meta/meta.dart';

import 'page_common.dart';
import 'page_data.dart';

/// Event detail page data with common page structure and event-specific labels.
///
/// Server provides:
/// - `pageData`: Pre-computed PageData with hero (from event), CTA
///   (state-based), etc.
/// - `labels`: Event-specific section labels
@immutable
class EventDetailPageData {
  const EventDetailPageData({required this.pageData, required this.labels});

  /// Common page structure: hero, activeSection, emptyState, cta.
  /// Server pre-computes hero from event entity and CTA based on event state.
  final PageData pageData;

  /// Event-specific section labels (about, highlights, fees, etc.).
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

@immutable
class EventDetailNotFoundLabels {
  const EventDetailNotFoundLabels({
    required this.pageTitle,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.buttonRoute,
    this.iconName = 'searchX',
  });

  final String pageTitle;
  final String title;
  final String description;
  final String buttonText;
  final String buttonRoute;
  final String iconName;

  /// Convert to generic NotFoundLabels for NotFoundPage widget.
  NotFoundLabels toNotFoundLabels() {
    return NotFoundLabels(
      pageTitle: pageTitle,
      title: title,
      description: description,
      buttonText: buttonText,
      buttonRoute: buttonRoute,
      iconName: iconName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventDetailNotFoundLabels &&
        other.pageTitle == pageTitle &&
        other.title == title &&
        other.description == description &&
        other.buttonText == buttonText &&
        other.buttonRoute == buttonRoute &&
        other.iconName == iconName;
  }

  @override
  int get hashCode => Object.hash(
    pageTitle,
    title,
    description,
    buttonText,
    buttonRoute,
    iconName,
  );
}
