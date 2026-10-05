# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`cl_club_website` is a club's public website: screens, router, navbar and shell, with no club in it. A host app supplies the club through its assets and starts it with `websiteMain()`: `example/` is the neutral host and the template a club's site is generated from (root `CLAUDE.md`, #186). It is club_core's second integrator beside `cl_club_app`; see the root `CLAUDE.md`.

## Development Commands

```bash
# Run the neutral host site
cd example && flutter run -d chrome

# Run against another server than club.json names
flutter run -d chrome --dart-define=CLUB_API_BASE_URL=http://127.0.0.1:8310/v1

# Analyze and test this package (from club_core/)
cd cl_club_website && dart analyze
just unit-test cl_club_website
```

## Build-time Configuration

The club comes from the host's `assets/club.json`; `--dart-define` overrides
parts of it at build time:

| Variable | Description | Example |
|----------|-------------|---------|
| `CLUB_API_BASE_URL` | API server URL, overriding `club.json`'s `apiBaseUrl` | `http://127.0.0.1:8310/v1` |
| `CLUB_MEMBER_APP_URL` | The member app, overriding `club.json`'s optional `memberAppUrl`; set, the navbar and drawer link to it (#179) | `https://beta-member.example.in` |
| `BUILD_TIMESTAMP` | Build stamp shown in the footer (`YYYYMMDDHHmmss`) | `20240407143045` |

`BUILD_TIMESTAMP` used to be a cache buster appended to every `/static/` URL
the SDK returned. Nothing builds those URLs any more — the site's own visuals
are bundled assets and server media is fetched by uuid — so it only labels the
footer now.

## Page title and description (#29)

Each page names itself to the browser and to search engines through
`PageMetaPublisher` (`pageMetaProvider`): `App` sets the browser title to
`<page name> | <club name>` and writes the description into the document's
`<meta name="description">`. `PublicPageShell` publishes for every page under
it: a listing is named by its nav label, a detail page by its `pageTitle`, and
the screen passes `description:` (hero copy, the About story, the coaches'
names, an event's tagline, a venue's address). A shell shown only while data
loads passes `publishMeta: false`. The home page keeps the description the site
was built with, which the generator takes from the brand's About story.
`websiteMain()` turns the semantics tree on for the web, so the page text is
in the document.

## Architecture

### Package Structure

A **template + host** structure, like club_core's `cl_club_app` and the club
apps:
- `lib/` - everything the site does; `lib/src/site/` holds `websiteMain()`,
  the app widget, router, navbar and shell
- the host (`example/`, or a project generated from it for a club):
  `main.dart` calls `websiteMain()`, and its assets are the club

### Host assets

| asset | read by | |
|---|---|---|
| `assets/club.json` | `SiteConfig` | same file and keys as the club apps, plus `map` |
| `assets/images/club_logo.png` | `ClubLogo` | same path as the club apps |
| `assets/images/instagram.png` | `InstagramMark` | optional; the "Follow us" mark, falling back to an icon when absent (#57) |
| `assets/data/contact_info.json` | `loadBundledContactInfo` | the club apps' shape; `bundledContactInfoProvider` (cl_remote_store), the fallback under `contactInfoProvider` for every field the server leaves out |
| `assets/l10n/app_en.arb` | `siteStringsProvider` | the site's copy |
| `assets/config/theme.json` | `themeConfigProvider` | colour tokens |
| `assets/media/*.webp` | `SiteMediaSlot.bundledAsset` | bundled hero slots |

`example/test/brand_files_test.dart` checks each is present and parses, and
that the ARB's keys match `SiteStrings.keys`; the generator runs it against
every brand's files. `instagram.png` is not yet carried by the generator.

### Key Dependencies

- **club_sdk_2** - the SDK (a git dependency on `cloudonlanapps/club_sdk`),
  for its data models; the site makes no SDK calls of its own
- **ui_lib** - club_core's shared UI widgets built on shadcn_ui (a path
  dependency, `../ui_lib`)
- **cl_remote_store** - every public read (a path dependency): the
  `clPublic*` providers (events, venues, staff, club info, club content, site
  media, media URLs, the inquiry form; club_core#53). The site media slots
  are shared with the admin screen that sets them (club_core#19); the
  bundled defaults stay here as `SiteMediaSlot.bundledAsset` /
  `bundledMedia`. Contact details are its `contactInfoProvider`, shared with
  the apps
- **cl_club_branding** - the contact button (`ContactFab`) and
  `launchContactUrl`, shared with the apps (a path dependency)
- **cl_club_events**, **cl_club_members**, **cl_club_venues** - the public
  event, coach and venue widgets (club_core#53): `PublicEvent*` cards,
  detail content, landing sections and their providers; `CoachCard` /
  `CoachesCardList`; `PublicVenueList` and `VenueContent`. They navigate by
  callback; the site supplies the paths through `SiteRoutes`
- **cl_gallery_viewer** - a git dependency pinned by SHA, as `ui_lib` takes it
- **shadcn_ui** - UI component library (similar to shadcn/ui for web)
- **go_router** - Routing with `ShellRoute` for static navbar during transitions
- **flutter_riverpod** - State management

A host site takes `cl_club_website` as a git dependency on club_core pinned by
SHA; these come through it from the same commit.

### Integration Pattern

A host's `main.dart` is `void main() => websiteMain();`. `websiteMain` reads
`club.json` and `contact_info.json` before the first frame and overrides
`siteConfigProvider` and cl_remote_store's `bundledContactInfoProvider`; the
app widget wraps every page in `SiteStringsGate`, which waits for the copy.

### Data Flow

1. `cl_remote_store`'s `clPublic*` providers read `/public` (token-free,
   auto-disposing, reporting to `networkStatusProvider`)
2. `cl_club_events` derives the event views from them
   (`publicEventsByTypeProvider`, `publicEventByIdProvider`,
   `publicHighlightsProvider`), wrapping each event as a `PublicEventView`
3. Screens consume providers and compose the feature packages' public
   widgets, handing each its navigation callbacks

The site's own copy is the host's ARB, read by `siteStringsProvider` (an
`AsyncNotifier`) and put in scope by `SiteStringsGate`; `SiteCopy` assembles it
into page shapes. It is data, not generated code: `SiteStrings` names the keys
and holds no text. Per-language copy from the server would change only the
provider — local ARB first, a downloaded language once it has fully arrived.

### Folder Conventions (lib/src/)

- `screens/` - Top-level page widgets with `Scaffold`
- `widgets/` - Reusable UI components
- `providers/` - Riverpod providers and notifiers
- `models/` - Data classes and typedefs
- `config/` - Configuration (e.g., `WebsiteShellConfig`)
- `extensions/` - Extension methods on SDK models

### Shell Architecture

- `PublicShellScaffold` (`lib/src/site/`) - Wraps pages with static navbar via `ShellRoute`
- `PublicPageShell` (library) - Adds breadcrumb, footer, and contact FAB to individual pages

### Public Routes

Routes follow `/public/` prefix pattern: `/`, `/public/programs`, `/public/events/:publicId`, etc. Events and venues are addressed by opaque public id, never the integer id.
