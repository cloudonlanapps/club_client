import 'package:flutter/foundation.dart';

/// Empty state data when no items are available.
///
/// Used by: events, programs, calendar, coaches.
/// The [description] field supports markdown formatting.
@immutable
class PageEmptyStateData {
  const PageEmptyStateData({
    required this.iconName,
    required this.title,
    required this.description,
    required this.buttonText,
  });

  /// Lucide icon name: 'sparkles', 'users', etc.
  final String iconName;
  final String title;
  final String description;
  final String buttonText;

  PageEmptyStateData copyWith({
    String? iconName,
    String? title,
    String? description,
    String? buttonText,
  }) {
    return PageEmptyStateData(
      iconName: iconName ?? this.iconName,
      title: title ?? this.title,
      description: description ?? this.description,
      buttonText: buttonText ?? this.buttonText,
    );
  }

  @override
  String toString() =>
      'PageEmptyStateData(iconName: $iconName, title: $title, description: '
      '$description, buttonText: $buttonText)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PageEmptyStateData &&
        other.iconName == iconName &&
        other.title == title &&
        other.description == description &&
        other.buttonText == buttonText;
  }

  @override
  int get hashCode =>
      iconName.hashCode ^
      title.hashCode ^
      description.hashCode ^
      buttonText.hashCode;
}
