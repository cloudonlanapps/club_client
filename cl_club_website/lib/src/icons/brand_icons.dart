import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Stand-ins for brand glyphs `lucide_icons_flutter` no longer ships.
///
/// Lucide removed all 126 brand marks — Instagram, Codepen, Dribbble and the
/// rest — between 3.1.10 and 3.1.17, an upstream licensing decision. Upgrading
/// to Flutter 3.47 forced that package bump, because 3.1.10 extends
/// `IconData`, which Flutter 3.44 made `final`.
///
/// The package's `assets/codepoints.json` still lists the old codepoints, but
/// that metadata is stale: the glyphs are gone from the font itself. Declaring
/// an `IconData` against the old codepoint compiles, then fails the build at
/// icon tree-shaking with "Codepoint 57594 not found in font".
///
/// So these are **placeholders, not the brand marks**. The real mark is an
/// image asset the host ships, a licensing decision for the club rather than
/// something to lift out of a package; these stand in when it ships none.
abstract final class BrandIcons {
  /// Placeholder for the Instagram mark, used by `InstagramMark` when the host
  /// has no `assets/images/instagram.png`. Renders a camera, which reads as
  /// "photos" beside a "Follow us" heading, but is **not** the brand logo.
  static const IconData instagram = LucideIcons.camera;
}
