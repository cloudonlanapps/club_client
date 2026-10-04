import 'package:cl_club_branding/cl_club_branding.dart'
    show ClubColorSource, ClubColorTokens, parseHexColor;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// The shadcn scheme the site's `theme.json` overrides.
const String kSiteColorSchemeName = 'blue';

/// Parsed theme config loaded from `assets/config/theme.json`.
///
/// Any token left out of the JSON resolves to `null` here and keeps the base
/// [kSiteColorSchemeName] scheme's value; [toColorSource] hands the rest to
/// `buildClubColorScheme`.
@immutable
class ThemeConfig {
  const ThemeConfig({
    required this.brandBlue,
    required this.light,
    required this.dark,
  });

  factory ThemeConfig.fromMap(Map<String, dynamic> map) {
    return ThemeConfig(
      brandBlue: parseHexColor(map[brandBlueKey] as String?),
      light: ClubColorTokens.fromMap(
        map[lightKey] as Map<String, dynamic>? ?? const {},
      ),
      dark: ClubColorTokens.fromMap(
        map[darkKey] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  /// theme.json key of [brandBlue].
  static const String brandBlueKey = 'brandBlue';

  /// theme.json key of [light].
  static const String lightKey = 'light';

  /// theme.json key of [dark].
  static const String darkKey = 'dark';

  /// The source used before theme.json has loaded, or if it fails to.
  static const ClubColorSource defaultColorSource = ClubColorSource(
    schemeName: kSiteColorSchemeName,
  );

  /// Primary / accent color, applied to both light and dark modes.
  /// Null means "use the scheme default".
  final Color? brandBlue;

  /// Light-mode token overrides.
  final ClubColorTokens light;

  /// Dark-mode token overrides.
  final ClubColorTokens dark;

  /// This config as the source of the site's colour scheme.
  ClubColorSource toColorSource() => ClubColorSource(
    schemeName: kSiteColorSchemeName,
    primary: brandBlue,
    light: light,
    dark: dark,
  );
}
