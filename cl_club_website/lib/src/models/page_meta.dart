import 'package:meta/meta.dart';

/// What the browser and a search engine are told about the page on screen.
@immutable
class PageMeta {
  const PageMeta({required this.title, this.description});

  /// The browser title.
  final String title;

  /// The page's description; null leaves the one the site was built with.
  final String? description;

  @override
  bool operator ==(Object other) =>
      other is PageMeta &&
      other.title == title &&
      other.description == description;

  @override
  int get hashCode => Object.hash(title, description);

  @override
  String toString() => 'PageMeta($title, $description)';
}
