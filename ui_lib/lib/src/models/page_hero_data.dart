import 'package:flutter/foundation.dart';

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
