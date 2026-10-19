import 'package:meta/meta.dart';

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
