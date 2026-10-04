import 'package:flutter/widgets.dart';

/// Workspace-wide responsive layout breakpoints.
///
/// Single source of truth for the mobile/compact cutoff. Surfaces keep
/// their own max-content widths (480, 420, …) because those are
/// intentionally variant per surface, but the mobile breakpoint itself
/// lives here so it can be changed in one place.
abstract final class Breakpoints {
  /// Layout widths below this are treated as a single-column "mobile"
  /// layout.
  static const double mobileMaxWidth = 600;
}

/// Whether the current layout width is below [Breakpoints.mobileMaxWidth].
///
/// Reads `MediaQuery.sizeOf` so it only depends on the size aspect of the
/// surrounding [MediaQuery].
bool isMobileWidth(BuildContext context) =>
    MediaQuery.sizeOf(context).width < Breakpoints.mobileMaxWidth;
