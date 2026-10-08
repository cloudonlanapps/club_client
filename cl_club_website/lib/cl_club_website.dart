/// A club's public website.
///
/// A site's `main.dart` is `void main() => websiteMain();`; everything that
/// makes it one club's site is in the host's assets. See `websiteMain`.
library;

// Config (for app to provide navbar)
export 'src/config/website_shell_config.dart' show WebsiteShellConfig;
// Extensions
export 'src/extensions/site_media_slot_bundled_asset.dart';
// The site's copy, read from the host's ARB.
export 'src/l10n/site_strings.dart' show SiteStringsScope;
// The club's identity, read from the host's assets.
export 'src/models/site_config.dart'
    show
        SiteConfig,
        kClubLogoAsset,
        kContactInfoAsset,
        kInstagramMarkAsset,
        kSiteConfigAsset,
        loadBundledContactInfo,
        siteConfigProvider;
// The site's own copy, and the shapes the pages read it in.
export 'src/page_content/event_detail_page_data.dart';
export 'src/page_content/landing_page_data.dart';
export 'src/page_content/page_common.dart';
export 'src/page_content/page_data.dart';
export 'src/page_content/page_type.dart';
export 'src/page_content/site_copy.dart';
export 'src/providers/contact_fab_visibility.dart';
// Providers.
//
// Exported wholesale, without `show` clauses, so the host app can override
// any of them from stub_overrides.dart. This package is retired during the
// club_core migration, so a narrower API surface would buy nothing.
export 'src/providers/member_app_uri.dart';
export 'src/providers/navbar_visibility.dart';
export 'src/providers/scroll_direction.dart';
export 'src/providers/site_strings.dart'
    show SiteStringsNotifier, kSiteStringsAsset, siteStringsProvider;
// Screens
export 'src/screens/home.dart' show LandingPage;
export 'src/screens/pages.dart'
    show
        ClubEventsPage,
        ContactUsPage,
        EventDetailPage,
        IceMastersPage,
        LearningCampsPage,
        TheClubPage,
        TheRinksPage,
        TrainingSessionsPage,
        VenuePage;
export 'src/screens/signup.dart' show SignupPage;
// Entry point
export 'src/site/website_main.dart' show websiteMain;
export 'src/widgets/club_logo.dart' show ClubLogo;
// Constants
export 'src/widgets/hero_section.dart' show heroThemeToggleTag;
export 'src/widgets/inquiry_view.dart' show InquiryView;
export 'src/widgets/not_found_page.dart' show NotFoundPage;
export 'src/widgets/page_data_scaffold.dart' show CtaSection, PageDataContent;
// Shared utilities (for navbar in app)
export 'src/widgets/route_labels.dart' show routeLabel;
export 'src/widgets/site_strings_gate.dart' show SiteStringsGate;
