import 'package:flutter/material.dart';

/// Configuration for the website shell, providing the navbar builder.
///
/// Wrap your app with this widget to provide a navbar to all public pages:
/// ```dart
/// WebsiteShellConfig(
///   navbarBuilder: (context) => const PublicNavbar(),
///   child: MaterialApp.router(...),
/// )
/// ```
class WebsiteShellConfig extends InheritedWidget {
  const WebsiteShellConfig({
    required this.navbarBuilder,
    required super.child,
    super.key,
  });

  /// Builder function that creates the navbar widget.
  final WidgetBuilder navbarBuilder;

  /// Returns the nearest [WebsiteShellConfig] ancestor.
  ///
  /// Throws if no ancestor is found.
  static WebsiteShellConfig of(BuildContext context) {
    final config = context
        .dependOnInheritedWidgetOfExactType<WebsiteShellConfig>();
    assert(config != null, 'No WebsiteShellConfig found in context');
    return config!;
  }

  /// Returns the nearest [WebsiteShellConfig] ancestor, or null if not found.
  static WebsiteShellConfig? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<WebsiteShellConfig>();
  }

  @override
  bool updateShouldNotify(WebsiteShellConfig oldWidget) {
    return navbarBuilder != oldWidget.navbarBuilder;
  }
}
