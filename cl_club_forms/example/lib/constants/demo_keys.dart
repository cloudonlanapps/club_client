import 'package:flutter/widgets.dart';

/// Keys of the demo's own parts, for the tests.
abstract final class DemoKeys {
  /// The card around the form.
  static const Key formCard = ValueKey('demo.formCard');

  /// The Validate button of the top bar.
  static const Key validate = ValueKey('demo.validate');

  /// The Reset button of the top bar.
  static const Key reset = ValueKey('demo.reset');

  /// The light / dark toggle.
  static const Key themeToggle = ValueKey('demo.themeToggle');

  /// The button that opens the sidebar on a narrow window.
  static const Key openSidebar = ValueKey('demo.openSidebar');

  /// The sidebar item of the entry with [id].
  static Key sidebarItem(String id) => ValueKey('demo.sidebar.$id');
}
