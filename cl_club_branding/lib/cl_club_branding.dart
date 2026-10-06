/// Club identity for the shared UI.
///
/// This package holds the *shape* of a club's identity — brand strings, the
/// logo widget, the footer, the colour scheme, the remembered light / dark
/// mode and the contact button — and none of any particular club's values.
/// The host app supplies those by overriding `appBrandingProvider`,
/// `appLogoUriProvider` and cl_remote_store's `bundledContactInfoProvider` in
/// its `ProviderScope`, so two club apps can share every widget here without
/// their assets or names colliding.
library;

// Moved to ui_lib so every package can open a contact link (#32); still
// exported here for the callers that take it from this package.
export 'package:ui_lib/ui_lib.dart' show launchContactUrl;

export 'src/extensions/theme_mode_ref.dart';
export 'src/models/club_branding.dart';
export 'src/models/club_color_source.dart';
export 'src/models/club_color_tokens.dart';
export 'src/providers/app_branding.dart';
export 'src/providers/app_logo.dart';
export 'src/providers/initial_theme_mode.dart';
export 'src/providers/theme_mode.dart';
export 'src/utils/club_color_scheme.dart';
export 'src/utils/hex_color.dart' show formatHexColor, parseHexColor;
export 'src/utils/is_dark_theme.dart';
export 'src/utils/neutral_ghost_button.dart';
export 'src/utils/theme_mode_storage.dart';
export 'src/widgets/app_footer.dart';
export 'src/widgets/app_logo.dart';
export 'src/widgets/contact_fab.dart' show ContactFab;
