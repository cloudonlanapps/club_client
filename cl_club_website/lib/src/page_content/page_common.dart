import 'package:meta/meta.dart';

/// Hero section data shared across multiple pages.
///
/// Used by: events, programs, calendar, coaches, locations, about, contact.
/// The [description] field supports markdown formatting.
@immutable
class PageHeroData {
  const PageHeroData({
    required this.title,
    this.badge,
    this.description,
    this.imageUri,
  });

  final String? badge;
  final String title;
  final String? description;
  final String? imageUri;

  PageHeroData copyWith({
    String? Function()? badge,
    String? title,
    String? Function()? description,
    String? Function()? imageUri,
  }) {
    return PageHeroData(
      badge: badge != null ? badge() : this.badge,
      title: title ?? this.title,
      description: description != null ? description() : this.description,
      imageUri: imageUri != null ? imageUri() : this.imageUri,
    );
  }

  @override
  String toString() =>
      'PageHeroData(badge: $badge, title: $title, description: $description, '
      'imageUri: $imageUri)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PageHeroData &&
        other.badge == badge &&
        other.title == title &&
        other.description == description &&
        other.imageUri == imageUri;
  }

  @override
  int get hashCode =>
      badge.hashCode ^
      title.hashCode ^
      description.hashCode ^
      imageUri.hashCode;
}

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

/// Generic not-found page labels used by detail pages.
/// Server-provided via page data JSON.
@immutable
class NotFoundLabels {
  const NotFoundLabels({
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

  NotFoundLabels copyWith({
    String? pageTitle,
    String? title,
    String? description,
    String? buttonText,
    String? buttonRoute,
    String? iconName,
  }) {
    return NotFoundLabels(
      pageTitle: pageTitle ?? this.pageTitle,
      title: title ?? this.title,
      description: description ?? this.description,
      buttonText: buttonText ?? this.buttonText,
      buttonRoute: buttonRoute ?? this.buttonRoute,
      iconName: iconName ?? this.iconName,
    );
  }

  @override
  String toString() =>
      'NotFoundLabels(pageTitle: $pageTitle, title: $title, description: '
      '$description, buttonText: $buttonText, buttonRoute: $buttonRoute, '
      'iconName: $iconName)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotFoundLabels &&
        other.pageTitle == pageTitle &&
        other.title == title &&
        other.description == description &&
        other.buttonText == buttonText &&
        other.buttonRoute == buttonRoute &&
        other.iconName == iconName;
  }

  @override
  int get hashCode =>
      pageTitle.hashCode ^
      title.hashCode ^
      description.hashCode ^
      buttonText.hashCode ^
      buttonRoute.hashCode ^
      iconName.hashCode;
}
