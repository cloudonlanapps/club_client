import 'package:flutter/foundation.dart';

/// CTA section data at bottom of pages.
///
/// Used by: events, programs, calendar.
/// The [description] field supports markdown formatting.
///
/// Primary button is always shown (label and route are required).
/// Secondary button is only shown when both label and route are provided.
@immutable
class PageCtaData {
  const PageCtaData({
    required this.title,
    required this.description,
    required this.primaryButtonText,
    required this.primaryRoute,
    this.primaryButtonIcon,
    this.secondaryButtonText,
    this.secondaryButtonIcon,
    this.secondaryRoute,
  });

  final String title;
  final String description;
  final String primaryButtonText;

  /// Route for primary button. Required - must be provided by server.
  final String primaryRoute;

  /// Lucide icon name for primary button: 'mail', 'arrowRight', etc.
  final String? primaryButtonIcon;

  /// Secondary button text. Button only shown if both this and route are set.
  final String? secondaryButtonText;

  /// Lucide icon name for secondary button: 'mapPin', 'graduationCap', etc.
  final String? secondaryButtonIcon;

  /// Route for secondary button. Button only shown if both this and text are
  /// set.
  final String? secondaryRoute;

  PageCtaData copyWith({
    String? title,
    String? description,
    String? primaryButtonText,
    String? primaryRoute,
    String? Function()? primaryButtonIcon,
    String? Function()? secondaryButtonText,
    String? Function()? secondaryButtonIcon,
    String? Function()? secondaryRoute,
  }) {
    return PageCtaData(
      title: title ?? this.title,
      description: description ?? this.description,
      primaryButtonText: primaryButtonText ?? this.primaryButtonText,
      primaryRoute: primaryRoute ?? this.primaryRoute,
      primaryButtonIcon: primaryButtonIcon != null
          ? primaryButtonIcon()
          : this.primaryButtonIcon,
      secondaryButtonText: secondaryButtonText != null
          ? secondaryButtonText()
          : this.secondaryButtonText,
      secondaryButtonIcon: secondaryButtonIcon != null
          ? secondaryButtonIcon()
          : this.secondaryButtonIcon,
      secondaryRoute: secondaryRoute != null
          ? secondaryRoute()
          : this.secondaryRoute,
    );
  }

  @override
  String toString() =>
      'PageCtaData(title: $title, description: $description, '
      'primaryButtonText: $primaryButtonText, primaryButtonIcon: '
      '$primaryButtonIcon, secondaryButtonText: $secondaryButtonText, '
      'secondaryButtonIcon: $secondaryButtonIcon, primaryRoute: '
      '$primaryRoute, secondaryRoute: $secondaryRoute)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PageCtaData &&
        other.title == title &&
        other.description == description &&
        other.primaryButtonText == primaryButtonText &&
        other.primaryButtonIcon == primaryButtonIcon &&
        other.secondaryButtonText == secondaryButtonText &&
        other.secondaryButtonIcon == secondaryButtonIcon &&
        other.primaryRoute == primaryRoute &&
        other.secondaryRoute == secondaryRoute;
  }

  @override
  int get hashCode =>
      title.hashCode ^
      description.hashCode ^
      primaryButtonText.hashCode ^
      primaryButtonIcon.hashCode ^
      secondaryButtonText.hashCode ^
      secondaryButtonIcon.hashCode ^
      primaryRoute.hashCode ^
      secondaryRoute.hashCode;
}
