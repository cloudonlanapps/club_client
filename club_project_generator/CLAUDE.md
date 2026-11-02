# club_project_generator

## Templates and the project generator (#186)

A club's web project is generated, not maintained: `club_project_generator`
copies a template, swaps in a **brand folder**, and the result builds with
`flutter build web` against this checkout. Each environment builds the
club_core that matches its server, so the app's code is club_core's own at that
commit and only brand files cross versions. Web only for now.

| template | target |
|---|---|
| `cl_club_app/example` | `app` (the member app) |
| `cl_club_website/example` | `website` |

```
<brand>/                 # club_project_generator/example_brand is a complete neutral one
  club.json              # one file for app and website; no URLs
  contact_info.json
  club_logo.png
  icon_1024.png          # square, >= 512 px; the 32 px favicon and web icons come from it
  website/               # needed only for the website target
    app_en.arb           # the site's text
    theme.json
    media/               # optional: replaces landing_background.webp / page_hero_default.webp
```

```bash
just generate app <brand> <out> --api-url <url> [--website-url <url>]
just generate website <brand> <out> --api-url <url> [--app-url <url>] [--website-url <url>]
just generator-test               # the generator's own tests
just generator-build-example      # both targets from example_brand, built for the web
just generator-build-example-android   # the app from example_brand, built as an APK
```

Rules:

- **URLs are input, never derived.** `--api-url`, `--app-url` and
  `--website-url` are whole http(s) URLs written into `club.json` as given; the
  generator assumes no host or prefix.
- **Android is opt-in, for the app (#280).** `--android-id <id>` copies the
  template's `android/` (no build output or local files) and writes that
  application id, the name (`--android-name`, default club.json's
  `shortName`) and launcher icons from `icon_1024.png`. Cleartext HTTP is
  allowed only when `--api-url` is `http://`. The template's own id stays the
  neutral `com.example.cl_club_app_example`.
- **`robots.txt` and `sitemap.xml` need the website's own URL.** Given
  `--website-url`, the website target writes both under `web/`: the sitemap
  lists the fixed public pages and the listing of each event type in
  `club.json`'s `eventTypes` (`sitemapRoutes`, checked against the site's
  router by the generator's tests). Without it neither file is written (#29).
- **The website describes itself with its About story.** The description in
  the website's `index.html` and `manifest.json` is the opening paragraph of
  the brand's About copy (`clubHistoryParagraph1` in `website/app_en.arb`), as
  one plain line of at most 160 characters; a brand without one keeps
  `<fullName> - Official Website` (#29).
- **Only the app is installable, as `<shortName> Member App` (#367).** The
  app's manifest names it `<shortName> Member App`, with `Member App` under
  its icon, and its page and tab carry the same title (`installedNames`;
  `memberAppTitle` in cl_club_app). The website's manifest is
  `"display": "browser"`, so a browser does not offer to install it, and it
  keeps the club's own names.
- **`club.json` must tolerate both directions.** One brand file is built against
  several club_core branches, so its readers (`ClubConfig`, `SiteConfig`)
  ignore unknown keys, and a key added later must be optional with a default.
- **The page sets its own Content-Security-Policy** (#315): a meta tag the
  generator builds from `--api-url` (`contentSecurityPolicy` in
  `web_files.dart`). The template runs no inline script (its own script is
  `templates/web/index.js`) and loads none from another origin (#314). A
  package that starts loading from, framing or connecting to a new origin
  adds it to that policy in the same change, or the browser refuses it.
- **Splash and browser-chrome colours** come from an optional `web` block in
  `club.json` (`backgroundLight`, `backgroundDark`, `accentLight`,
  `accentDark`, each `#RRGGBB`); missing ones are neutral.
- **`test/brand_files_test.dart` in each template is the brand validation.** It
  runs against the neutral files here and, after generating, against every
  brand's; a failure stops the build. A new brand file a package reads gets a
  check there.
- **The templates stay neutral and buildable.** A change to an example's
  `lib/`, `pubspec.yaml` or assets reaches every club's next build.
- **Branches:** `main`, `beta_release` and `release` mirror club_server's and
  are promoted with it (`main → beta_release → release`): dev builds `main`,
  beta `beta_release`, prod `release`. A release is tagged
  `RELEASE_VERSION_<major>_<minor>_<patch>`.
- **`VERSION` at the repo root is the only version number.** No
  `pubspec.yaml` here carries a `version:` (the generator's tests fail if
  one does); the generator writes `VERSION` into each project it creates, so
  a built app and website report it. It moves with club_server's: the major
  at each release, the patch for a quick fix (#153).
