import 'package:cl_club_website/src/widgets/scroll_direction_detector.dart'
    show ScrollDirectionDetector;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Scroll direction for mobile navbar hide/show behavior.
///
/// This provider is actively updated by [ScrollDirectionDetector] on detail
/// pages (wrapped in `PublicPageShell`) and by the landing page's inline
/// scroll listener, but is currently NOT read by any consumer. It was
/// originally wired into `PublicShellScaffold` so the navbar would hide on
/// scroll-down and reappear on scroll-up on mobile. That consumer was
/// removed because the detector only emits `up`/`down` during active
/// scrolling and never transitions back to `idle` when the user stops
/// mid-page — so once hidden, the navbar would not reappear until the user
/// scrolled up or reached the very top.
///
/// The provider (and [ScrollDirectionDetector]) are kept wired up so the
/// feature can be re-enabled easily. Before re-wiring, consider also
/// handling `ScrollEndNotification` or adding a debounce timer that resets
/// to `idle` when scrolling stops.
enum ScrollDirection { up, down, idle }

/// Provider tracking the current scroll direction.
///
/// See the note on [ScrollDirection] — currently written but not read.
final scrollDirectionProvider = StateProvider<ScrollDirection>(
  (ref) => ScrollDirection.idle,
);
