import 'package:flutter/foundation.dart';

/// Section header data for list sections (Active/Past).
///
/// Used by: events, calendar.
/// The [description] field supports markdown formatting.
@immutable
class PageSectionHeaderData {
  const PageSectionHeaderData({
    required this.badge,
    required this.title,
    required this.description,
    this.buttonText,
  });

  final String? badge;
  final String title;
  final String? description;

  /// Optional button text for sections that need a CTA button.
  final String? buttonText;

  PageSectionHeaderData copyWith({
    String? badge,
    String? title,
    String? description,
    String? Function()? buttonText,
  }) {
    return PageSectionHeaderData(
      badge: badge ?? this.badge,
      title: title ?? this.title,
      description: description ?? this.description,
      buttonText: buttonText != null ? buttonText() : this.buttonText,
    );
  }

  @override
  String toString() =>
      'PageSectionHeaderData(badge: $badge, title: $title, description: '
      '$description, buttonText: $buttonText)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PageSectionHeaderData &&
        other.badge == badge &&
        other.title == title &&
        other.description == description &&
        other.buttonText == buttonText;
  }

  @override
  int get hashCode =>
      badge.hashCode ^
      title.hashCode ^
      description.hashCode ^
      buttonText.hashCode;
}
