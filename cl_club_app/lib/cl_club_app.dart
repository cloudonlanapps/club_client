/// The club application: routing, theme and startup.
///
/// A club app supplies only its identity — an `assets/club.json`, a logo and
/// contact details — and calls `clubMain`. Everything else lives here, so the
/// two clubs share one implementation rather than two copies that drift.
library;

export 'src/app.dart' show App;
export 'src/club_main.dart' show clubConfigProvider, clubMain;
export 'src/models/bundled_contact_info.dart' show loadBundledContactInfo;
export 'src/models/club_config.dart'
    show
        ClubConfig,
        kClubConfigAsset,
        kClubContactAsset,
        kClubLogoAsset,
        kDefaultClubEventTypes,
        kShadColorSchemeNames;
export 'src/router.dart' show routerProvider;
