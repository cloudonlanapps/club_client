# club_client — shared club app packages

Mono-repo of the packages shared by every club app and website. It contains **no
club's identity**: its only applications are the two neutral examples,
`cl_club_app/example` (the member app) and `cl_club_website/example` (the
website), which are also the templates every club's web project is generated
from (see `club_project_generator/CLAUDE.md`).

Published from `club_core` (Oct 2026) with fresh history. Issue references in
code, comments and test names (`#186`, `club_core#186`, `Issue 186:`) are that
repo's numbers; `club_server#N` is the API server's tracker.

Where the detail lives:

| Topic | File |
|---|---|
| Writing or hosting a form, section editors | [`docs/form_rules.md`](docs/form_rules.md) — **read before touching a form or its host** |
| Coding standards (file layout, size limits) | [`docs/coding_rules.md`](docs/coding_rules.md) |
| Project generator, templates, brand folder | `club_project_generator/CLAUDE.md` |
| Credit UI | `cl_club_credits/CLAUDE.md` |
| Applications, extended profile | `cl_club_applications/CLAUDE.md`, [`docs/applications_design.md`](docs/applications_design.md) |
| Master providers | `cl_remote_store/CLAUDE.md`, [`cl_server_config/docs/master_providers.md`](cl_server_config/docs/master_providers.md) |
| App / website integration suites | `cl_club_app/example/CLAUDE.md`, `cl_club_website/CLAUDE.md` |
| Contributor workflow | [`CONTRIBUTING.md`](CONTRIBUTING.md) |

Module roles: each `<module>/pubspec.yaml` `description:`; dependencies: its
`dependencies:` block. The rules below are the contract those must respect.

## Consumers and dependencies

A club's project is generated inside a checkout of this repo, so its path
dependencies point straight at these packages. Anything else taking a package
from here uses a **git dependency pinned by SHA**, never a submodule.

`cl_calendar`, `cl_gallery_viewer` and the SDK (`club_sdk_2`, in
`cloudonlanapps/club_sdk`) are git dependencies pinned by SHA; the workspace
holds a checkout of each under `packages/`, and commented
`dependency_overrides` blocks point there for local work. Every package takes
the SDK at the **same** SHA: bump every `ref:` together. SDK tests live in that
repo.

## The two integrators

`cl_club_app` and `cl_club_website` are the only packages a club's app or site
calls: `main.dart` calling `clubMain()` / `websiteMain()` plus assets. Both read
`assets/club.json`, `assets/images/club_logo.png`,
`assets/data/contact_info.json`; the site adds `assets/l10n/app_en.arb` (read at
runtime by `siteStringsProvider`, never generated into code),
`assets/config/theme.json` and bundled media. An integrator provides routes,
shell, copy and screens composed from feature packages; it owns no domain.

**Templates stay neutral and buildable**: a change to an example's `lib/`,
`pubspec.yaml` or assets reaches every club's next build. **`club.json` must
tolerate both directions**: readers ignore unknown keys, and a new key is
optional with a default. Branches `main → beta_release → release` mirror
club_server's (dev/beta/prod). `VERSION` at the repo root is the only version
number: no `pubspec.yaml` carries `version:`. A package that starts loading
from, framing or connecting to a new origin adds it to the page's
Content-Security-Policy (`contentSecurityPolicy` in the generator's
`web_files.dart`) in the same change (#315). A new brand file a package reads
gets a check in the template's `test/brand_files_test.dart`.

`club.json` `eventTypes` (`camp`, `programme`, `oneOff`; absent = camps only)
overrides `clubEventTypesProvider`; the staff events master, occurrence feed,
sidebar lists and Create Event cover those types only.

## The club-neutrality rule

**No package here may name a club.** Brand strings, logo, contact details and
the API origin arrive by provider override from the host app:

| what | provider | lives in |
|---|---|---|
| full + short club name | `appBrandingProvider` | `cl_club_branding` |
| logo URI | `appLogoUriProvider` | `cl_club_branding` |
| contact details (bundled fallback) | `bundledContactInfoProvider` | `cl_remote_store` |
| API origin | `serverConfigProvider` | `cl_server_config` |

Contact details are read through `contactInfoProvider`, never overridden: it
prefers the server's club identity field by field over the bundled block. A
hardcoded club name, asset path or URL in any package is a bug. `ui_lib` and
`cl_club_forms` stay Riverpod-free: their widgets take plain parameters.

## Package boundaries

- **Server config → `cl_server_config` only.** The host overrides
  `serverConfigProvider`; modules read `apiBaseUrlProvider` /
  `serverConfigProvider`. No hardcoded URLs, no duplicate base-URL or
  network-status providers or failure widgets. `networkStatusProvider` is
  reactive (no polling): data providers call `checkNow()` on a failed fetch and
  `markOnline()` on success; an online failure is confirmed once a second later
  (#163). Shells wrap content in `NetworkStatusWrapper`, which keeps the page
  mounted under a banner; `NetworkFailureScreen` is for a view with nothing to
  show until the server answers.
- **Auth → `cl_member_auth` only.** Others use `authStateProvider`,
  `clientProvider`, `tokenStorageProvider`; no auth providers, notifiers,
  session models or auth-related widgets elsewhere (re-exports allowed).
- **SDK calls → `cl_remote_store` (domain resources, via
  `secureClientProvider`, which it defines and the host overrides) and
  `cl_member_auth` (auth operations).** Nobody else calls the SDK; widgets call
  mutation methods on master notifiers.

## Routes, screens and views

- Only `cl_club_app` (`lib/src/router.dart`, `routerProvider`) builds route
  strings, and it never imports feature-package views. Each route mounts a
  `…Screen` from the package owning its shell: `/auth/**` → `cl_member_auth`,
  `/onboarding/**` → `cl_member_onboarding`, the rest → `cl_member_zone`
  (`lib/src/screens/`). Use the exact view names there; don't invent variants.
- Shells (`AuthShell`, `OnboardingShell`, `MemberZoneShell`) own the chrome and
  **do not gate**.
- **Screens gate.** Role gates use `RoleGate` (`.admin`, `.coachOrAdmin`,
  `.superAdmin`); a non-role gate keeps its own check and refuses with
  `AccessDeniedView`, never a hand-written error. The screen forwards
  `currentUser` and parameters to the same-named view. Every public view takes
  `required UserPrivate currentUser` and never watches `authStateProvider` for
  it.
- **Views decide what renders inside** (admin buttons, role sections) from the
  user's roles. Don't expose admin actions as callbacks the caller must gate. A
  view that branches on `currentUser` state `assert`s its precondition at the
  top of `build`.
- **No navigation in feature packages.** No `context.go/push/pop`,
  `GoRouter.of(...)` or `Navigator` push/pop that leaves the screen; use
  callbacks (`onBack`, `onDeleted`, …). The sidebar names entries with
  `SidebarDestination`, mapped by `memberZoneSidebarRoute`. Exception:
  `Navigator.pop([result])` closing a dialog/sheet the widget itself opened.
  The router uses the `context.*` style.
- **Broadcast**: one screen, `/memberzone/broadcast`, the audience as a filter
  (`?group=`, `?event=`, `?member=`), each broadcast tagged with its
  `payload.source` (`BroadcastScope`). A new place that sends messages opens
  this screen; no other composer (club_client#252).

## Loading states

A view shows its loading state only before its first data. A reload updates in
place, never swapping in `LoadingView` / a spinner (that loses typed text and
scroll; club_client#162): `skipLoadingOnReload: true`, or
`value.isLoading && !value.hasValue`. Test it by reloading through a dependency
(bump `clManualRefreshProvider`), not `ref.invalidate`.

## Dates and instants

- **Date-only values** (DOB, credit validity, rest days) are **UTC midnight**.
- **Instants** take the viewer's local day:
  `DateUtils.dateOnly(instantUtc.toLocal())`. A day/month range sent to the
  server is local bounds converted: `DateTime(y, m).toUtc()`, never
  `DateTime.utc(y, m)` (club_client#209).

Daylight saving is not supported (every deployment is IST). Calendar code that
steps days with 24-hour `Duration`s is known and accepted: don't flag it in a
review (finding 20, 2026-10-21).

## Forms (summary — full rules in `docs/form_rules.md`)

Every `ShadForm` lives in `cl_club_forms`, SDK-free and Riverpod-free; its
dialog or screen lives in the feature package, with one adapter
(`build<X>FormInitialValues`, `<X>FormSubmit.update<Section>`). The host drives
the form through a `GlobalKey` (`validate()`, `isDirty`, `showErrors`,
`enabled`). Editing is section by section, inline, with `EditableSectionCard`;
no edit routes. Refused saves show on the field, inline, or (only for
non-input failures) as a toast; never a raw error.

## UI style

- **Colour carries a state, never decoration.** Settled uses (finding 49,
  2026-10-21; don't flag them): attendance states and leave requests; enrolment
  states; the role stamps over a profile photo; calendar day states with a
  legend; failure screens in `destructive`. A new state colour joins this list
  first. Colours come from the theme; status labels are readable text.
- Bordered, rounded, spacious cards; thin dividers between items.

## Project workflow

The project is **stable**: read [`CONTRIBUTING.md`](CONTRIBUTING.md) (issue
first, branches, PRs, labels) before any code change. Agent-only additions:

- **Process files** (`CLAUDE.md` anywhere, `CONTRIBUTING.md`, `docs/`) need no
  issue: commit to `main` (from a feature branch: commit on `main`, push,
  cherry-pick back).
- **Confirm first:** `git push`, `gh pr create`, `gh pr merge` (never to
  `release`), `gh pr close`, `gh issue close`, force-push, `reset --hard`,
  branch deletion, label definitions / milestones / repo settings. Reading,
  local branches, edits, tests, local commits and applying labels need no
  confirmation.
- **Status labels:** move the issue's `status:*` label yourself at each step
  (branch → `status:in-progress`, merge → remove it).
- **Implementing issue #N:**
  1. Check the server (a club_server checkout) supports the behaviour; if not,
     file a server issue and mark this one `status:blocked`.
  2. Confirm the bug still exists; if fixed, report and close, no no-op PR.
  3. Write a failing test first if none covers it; new test names start with
     `Issue N:`.
  4. Try to un-skip `skip:` tests for the issue, or say in the PR why not.
  5. List the confirming tests (names and paths) in the commit or PR.
  6. `git add` specific files.
  7. Commit messages and PRs say what the change does, never rejected
     alternatives or "this does not use X".
- **Merging:** always ask squash or rebase. Never `--merge`, never
  `--delete-branch`. Afterwards remove `status:in-progress`.

## Tooling

- **Flutter** is not pinned: use the one on `PATH`. Unexpected `pubspec.lock`
  changes (`matcher`, `test_api`) mean a different SDK — check
  `flutter --version`.
- **Dependencies** are pinned to exact versions (no caret, `any` or ranges,
  except `environment`). Upgrades are deliberate, never a side effect of
  `pub get`.
- **Lint:** run the `lint-baseline-check` agent before pushing or releasing.
- **Commands:** `justfile` (needs just ≥ 1.27; `just --list` shows all):

```bash
cd <module> && dart analyze
just unit-test-all                  # every package's and both examples' unit + widget tests
just unit-test <pkg>
just app-test                       # member app UI integration, once per server conf
just app-test-one <conf> <file>
just website-test                   # website integration, once per server conf
just website-test-one <conf> <file>
```

Server-backed recipes each start their own isolated stack (native_deploy,
cloned into gitignored `.native_deploy/`, free ports, torn down on exit;
`keep=1` leaves it up, then `just stop-app-test-server <server_port>
<db_port> <conf>`). Before committing, run the relevant suites. The two confs
differ in capabilities (see `cl_club_app/example/CLAUDE.md`); tests expect from
`/v1/capabilities`, never from the club.
