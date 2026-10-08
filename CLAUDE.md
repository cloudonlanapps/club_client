# club_client — shared club app packages

Mono-repo of the packages shared by every club app and website. It contains **no
club's identity**: its only applications are the two neutral examples,
`cl_club_app/example` (the member app) and `cl_club_website/example` (the
website), which are also the templates every club's web project is generated
from (see *Templates and the project generator* below).

A club provides only a brand folder; a deploy tool generates its app and site
from this repo's templates at the branch matching its server.

This repo was published from `club_core` (Oct 2026) with fresh history. Issue
references in code, comments and test names (`#186`, `club_core#186`,
`Issue 186:`) are that repo's numbers and predate this one; `club_server#N`
refers to the API server's tracker.

## Consumers

A club's project is generated inside a checkout of this repo, so its path
dependencies point straight at these packages: nothing is pinned by SHA. Anything
else taking a package from here uses a **git dependency pinned by SHA**, never a
submodule.

`cl_calendar` and `cl_gallery_viewer` are not carried here. Both are git
dependencies pinned by SHA, for the same reason; the workspace holds one
checkout of each under `packages/`, and the commented `dependency_overrides`
block in `cl_club_events`, `cl_club_forms`, `cl_club_website` and `ui_lib`
points at it for local work.

The SDK is not carried here either. The package `club_sdk_2` lives in the
public repo `cloudonlanapps/club_sdk` (#65) and every package that uses it takes
it as a git dependency pinned by SHA, all at the **same** SHA; its commented
`dependency_overrides` entry points at the workspace's `packages/club_sdk`. Bump
every `ref:` together. The SDK's unit and integration suites, and their
`just` recipes, live in that repo.

## The two integrators

`cl_club_app` and `cl_club_website` are the only packages a club's app or site
calls: a club app is `main.dart` calling `clubMain()` plus its assets, and a
club site is `main.dart` calling `websiteMain()` plus its assets. Both read
the same identity files at the same paths — `assets/club.json`,
`assets/images/club_logo.png`, `assets/data/contact_info.json` — and the site
adds its copy (`assets/l10n/app_en.arb`, read at runtime by
`siteStringsProvider`, never generated into code), `assets/config/theme.json`
and bundled media.

An integrator provides routes, shell, copy and screens, composed from the
feature packages; it does not own domains. `cl_club_website` arrived (#52)
still carrying its own public data providers and event, coach and venue
widgets; #53 moves each into the package that owns it.

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
  icon_1024.png          # square, >= 512 px; favicon and web icons come from it
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
```

Rules:

- **URLs are input, never derived.** `--api-url`, `--app-url` and
  `--website-url` are whole http(s) URLs written into `club.json` as given; the
  generator assumes no host or prefix.
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
- **`club.json` must tolerate both directions.** One brand file is built against
  several club_core branches, so its readers (`ClubConfig`, `SiteConfig`)
  ignore unknown keys, and a key added later must be optional with a default.
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

## Club event types (club.json)

`club.json` may carry `eventTypes` — the event types the club runs (`camp`,
`programme`, `oneOff`). Absent means camps only. `clubMain()` overrides
`clubEventTypesProvider` (cl_remote_store) from it; the staff events master
(`clEventsMasterProvider`), the staff occurrence feed, the sidebar lists and
the Create Event quick action cover these types only (#115, #122).

## Credit UI (cl_club_credits)

Credit has exactly two UI pieces (#101, #102):

- **`CreditChip`** — a member's usable credit as a coin and a number. It
  renders nothing unless `creditSystemProvider` is `true` (never guess; no
  credit call otherwise). Tapping it opens the member's `CreditView` in a
  full-height `ShadSheet` (`showCreditSheet`): a modal the chip opens, so no
  route plumbing, and it works over dialogs. `CreditChip.add`, the "+" chip
  of a member a picker cannot fund, does **not** open the sheet: it opens Add
  credit alone in a dialog over the picker (`showCreditGrantDialog`),
  pre-filled with the programme and trial flag (club_client#41). Only an
  admin may add credit, so "+" renders nothing for anyone else: an organizer
  who is not an admin sees the number chip alone (club_client#49). In the
  pickers (Assign Users, Assign Trial) a member with no usable credit shows
  two chips side by side: the coin and `0` (a number chip, so it opens the
  sheet) and then, for an admin, "+". A funded member shows the number chip only; once "+"
  is saved the row turns into that form.
- **`CreditView`** — usable total, packages, statement (server `totalAfter`,
  never recomputed), and admin-only actions. `/memberzone/credit/:username`
  (`CreditScreen`) mounts it only for the `credit.released` deep link.

Credit actions open in place (club_client#41): Add credit, Extend, Reverse and
Transfer show their form inside the view (`CreditActionForm.inPlace` in a
`CreditActionPanel`, with Cancel and Save) in place of the packages and the
statement, which return when the form closes. The view pushes no dialog and
opens nothing when it mounts, so from a chip inside a dialog the deepest stack
is that dialog and the sheet. `CreditActionForm` is the one connected host of
the four `cl_club_forms` credit forms; `CreditActionDialog` hosts Add credit for the "+"
chip only.

Rules: actions credit forbids are greyed out up front — `ActionItem.reason`
carries the chip beside the disabled action — never tried and then shown as
an error (catch-and-toast stays as the safety net). Programmes only. The
funding rule mirrors the server: usable general or this-programme credit
with a matching trial flag (`usableCreditsFor`). The app never sends
`creditDisposition`: programme credit is settled in the credit view first.

State: masters in cl_remote_store (`clCreditAccountsMasterProvider`,
`clCreditEntriesMasterProvider`, `clEventCreditRosterProvider`,
`clUsableCreditAccountsProvider`) plus derived providers; anything that moves
credit (credit actions, marks, leave decisions, enrollment changes) bumps
`creditsVersion`, which every credit provider watches.

## The club-neutrality rule

**No package here may name a club.** Brand strings, logo, contact details and
the API origin all arrive by provider override from the host app:

| what | provider | lives in |
|---|---|---|
| full + short club name | `appBrandingProvider` | `cl_club_branding` |
| logo URI | `appLogoUriProvider` | `cl_club_branding` |
| contact details (bundled fallback) | `bundledContactInfoProvider` | `cl_remote_store` |
| API origin | `serverConfigProvider` | `cl_server_config` |

Contact details are read through `contactInfoProvider` (cl_remote_store), never
overridden: it prefers the server's public club identity field by field over
the bundled block that `clubMain()` / `websiteMain()` load from
`assets/data/contact_info.json` (#53). One `ContactFab` (cl_club_branding) serves
the apps' shells and the website.

A hardcoded club name, asset path or URL in any package here is a bug — it makes
the package unusable for the other club. `ui_lib` and `cl_club_forms` additionally stay Riverpod-free
(see the form rules below), so widgets there take plain parameters and their
provider-backed wrappers live in `cl_club_branding` or the feature packages.

For module roles, see each `<module>/pubspec.yaml` `description:` field. For inter-module dependencies, see each module's `pubspec.yaml` `dependencies:` block. The boundary rules below are the contract those dependencies must respect.

## View naming

Routes are defined in `cl_club_app/lib/src/router.dart` (`routerProvider`). Each route mounts a `Screen` (suffix `Screen`) from the package that owns its domain shell — `cl_member_auth/lib/src/screens/` for `/auth/**`, `cl_member_onboarding/lib/src/screens/` for `/onboarding/**`, `cl_member_zone/lib/src/screens/` for post-onboarding authenticated routes. The screen wraps a same-named view in the underlying feature package. **Use the exact view names from those directories — do not invent variants** (no "Admin Calendar", etc.).

## Server Configuration Rules

**All server configuration lives in `cl_server_config`.** This is a strict boundary:

- The API base URL is provided via `serverConfigProvider` / `ServerConfig`. The host app **must** override `serverConfigProvider` in its `ProviderScope`.
- **Do not** hardcode API URLs in any module. If a module needs the base URL, it must depend on `cl_server_config` and use `apiBaseUrlProvider` or `serverConfigProvider`.
- **Do not** create duplicate base URL providers, network status providers, or network failure widgets in any other module. These all come from `cl_server_config`.
- Network status detection (`networkStatusProvider`) is **reactive** — no background polling. Data providers call `checkNow()` when a fetch fails and `markOnline()` when one succeeds.
- Network failure UI (`NetworkStatusWrapper`, `NetworkFailureScreen`) is provided by `cl_server_config`. Shell scaffolds wrap their content with `NetworkStatusWrapper`.

## Authentication Rules

**All authentication logic lives in `cl_member_auth`.** This is a strict boundary:

- Every module that needs authentication **must** depend on `cl_member_auth` and use its providers (`authStateProvider`, `clientProvider`, `tokenStorageProvider`).
- **Do not** duplicate auth logic (login, logout, session persistence, token storage, status checking) in any other module. If `cl_club_members`, `cl_member_zone`, or any new module needs auth functionality, it must import from `cl_member_auth`.
- **Do not** create auth-related providers, notifiers, or session models outside `cl_member_auth`. If a module needs to read auth state, it watches `authStateProvider`. If it needs the SDK client, it reads `clientProvider`.
- Any new widget or view related to authentication (login forms, signup flows, password management, account status displays, auth-gating widgets) **must** be implemented in `cl_member_auth`, not in consuming modules.
- Consuming modules may re-export auth symbols from `cl_member_auth` for backward compatibility (as `cl_club_members` and `cl_member_zone` currently do), but must not define their own.

## Module View Wrapping Rule

**The app's router (`cl_club_app/lib/src/router.dart`) must not import views directly from feature modules** (`cl_club_events`, `cl_club_members`, `cl_club_venues`, …). Every route mounts a screen from the package that owns its domain shell:

- `/auth/**` → screens from `cl_member_auth/lib/src/screens/`.
- `/onboarding/**` → screens from `cl_member_onboarding/lib/src/screens/`.
- Post-onboarding authenticated routes → screens from `cl_member_zone/lib/src/screens/`.

Each screen:

- Watches `authStateProvider` from `cl_member_auth` to obtain the current user.
- Performs status / role / relationship gating using helpers from `cl_member_auth` (`userAllowedForEvents`, `myEventsAccessProvider`, `onboardingGateAllows`, …) and renders `AccessDeniedView` (or `ErrorView` with `tone: ErrorTone.neutral`) from `ui_lib` when the gate fails.
- Forwards `currentUser` and any path / navigation parameters to a same-named view in the underlying feature package.

Each public view in a feature package takes `required UserPrivate currentUser` so role-aware UI can rely on a non-null user. Views never watch `authStateProvider` themselves.

### Shells

Each domain shell — `AuthShell`, `OnboardingShell`, `MemberZoneShell` — wraps the screens in its `ShellRoute` and owns the chrome (Scaffold, app bar, footer, theme toggle). Shells **do not gate**; gating is the screen's job, and the shell is reached only via the matching `ShellRoute` in the app's router. Shells live with their package because of potential package-local data dependencies; each package's barrel exports its shell alongside its screens.

## No Hardcoded Routes in Sub-Packages

Only `cl_club_app` (which owns the GoRouter) constructs route strings. `cl_member_zone`, `cl_club_events`, `cl_club_members`, `cl_club_venues`, and any future feature module **must not** call `context.push` / `context.go` / `context.pop` with a hardcoded path, or `GoRouter.of(context).push/go(...)` with a hardcoded path. Navigation is expressed as callback parameters on screens and views (`onEventTap(int eventId)`, `onCreateNew()`, `onBack()`, …) and supplied by the router. Screens forward callbacks down to their wrapped views unchanged.

**Route navigation via `Navigator` is the same violation.** A view or shared widget must not move around the route stack by any API — neither the GoRouter forms above nor `Navigator.of(context).push(...)` / `Navigator.of(context).pop()` used to *leave the current screen* (e.g. popping the route after a save or delete). All of these become callbacks supplied by the screen (`onClose`, `onDeleted`, `onDismissed`, …).

The one exception is **modal dismissal**: `Navigator.of(context).pop([result])` used purely to close a dialog, bottom-sheet, or drawer that the widget itself opened is *not* route navigation — it is the canonical `showDialog → Navigator.pop(result)` idiom and is allowed in views and widgets. Litmus test: is the `pop` closing a modal this widget pushed, or navigating the app's route stack? The former is fine; the latter must be a callback.

When an app's router itself navigates, prefer the `context.go/push/pop` extension methods over the equivalent `GoRouter.of(context).go/push/pop(...)` — they are the same API, so pick one style (`context.*`) and keep it consistent.

## SDK Access Boundary

All SDK access is concentrated in two modules:

- **`cl_remote_store`**: All SDK calls for domain resources (users, venues, events, groups, enrollments, attendance, notifications, pending actions, broadcasts, etc.), via `secureClientProvider`. It also **defines** `secureClientProvider`; the host app overrides it with the authenticated client from `cl_member_auth`. Master providers live in `cl_remote_store/lib/src/providers/` — see [`cl_remote_store/CLAUDE.md`](cl_remote_store/CLAUDE.md) for the pattern (master notifier, widget mutation rule, optimistic updates, mutation response handling).
- **`cl_member_auth`**: SDK calls for auth operations only (login, logout, changePassword, getCurrentUser).
- **`cl_server_config`**: Defines `serverConfigProvider` (base URL) and network-status detection. Apart from a `/health` ping in `NetworkStatusNotifier`, `cl_server_config` itself makes no SDK calls.
- **No other module** should call SDK functions directly. Widgets call mutation methods on the relevant master notifier, never the SDK client.

Full master-provider inventory: [`cl_server_config/docs/master_providers.md`](cl_server_config/docs/master_providers.md).

## View Permission Guidelines

Permission checks split cleanly between screens and views:

- **Screens own route-level gating.** Whether the user is allowed to reach this route at all — by status, role, or relationship — is checked in the screen, which renders `AccessDeniedView` / `ErrorView` on failure.
- **Views own intra-view conditional rendering.** Whether to show an admin-only button, a status action, or a role-specific section inside an otherwise reachable view is the view's responsibility. Read `authStateProvider` for the current user's roles and conditionally render. Do not expose admin actions as callbacks that callers must gate — callers control navigation, not authorization.

Inside a view:

- Use `ref.watch(authStateProvider)` to get the current user's roles.
- Check `isAdmin`, `isSuperAdmin`, `isSelf` to decide which sections render.
- Navigation callbacks (`onBack`, `onContactEdit`) remain as parameters — the host controls *where* to navigate, not *whether* to show the action.

### Views assert their preconditions

Any view that branches on `currentUser` state (status, roles, note, relationship) must declare its precondition with `assert(...)` at the top of `build`. Asserts cost nothing at runtime (stripped in release), but turn a silent contract violation into a loud test failure if a future change weakens the screen gate.

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  assert(
    currentUser.status == UserStatus.registered ||
        currentUser.status == UserStatus.pending,
    'OnboardingWelcomeView called with unexpected status '
    '${currentUser.status}. Screen gate failed.',
  );
  // …
}
```

Asserts are **not a permission check** — screens still own authorization. Asserts only verify the contract the screen promised when it constructed the view.

---

## Project workflow

This project is **stable**. The full contributor workflow — issue-first rule, branch naming, PR rules, merge strategy, labels — is in [`CONTRIBUTING.md`](CONTRIBUTING.md). Read it before making any code change. The agent-only deltas below extend, not replace, that document.

### Exception for process files

Edits to any `CLAUDE.md` file (the root one and any module-scoped `<module>/CLAUDE.md`, e.g. `app/CLAUDE.md`, `cl_remote_store/CLAUDE.md`), to `CONTRIBUTING.md`, or to files under `docs/`, do not require an issue. Commit directly to `main`. If you are on a feature branch, switch to `main`, commit, push, then cherry-pick into the feature branch.

### Required confirmations (high-blast-radius actions)

Always pause and confirm with the user before:

- `git push` (to any branch)
- `gh pr create`
- `gh pr merge` — additionally, never merge to `release`
- `gh pr close`
- `gh issue close`
- Force-push, `git reset --hard`, branch deletion
- Editing label *definitions*, milestones, or repo settings

You may proceed without confirmation for:

- Reading issues, PRs, code, logs
- Creating local branches
- Editing files locally
- Running tests
- Local commits (not pushed)
- Applying or removing existing labels on issues via `gh issue edit`

### Issue status labels

The label rules — required `status:*` lifecycle, optional kind labels,
priority outside GitHub — are in [`CONTRIBUTING.md` › Labels](CONTRIBUTING.md#labels),
the single source. The agent-only delta: move an issue's `status:*` label at
each step of the flow yourself (branch → `status:in-progress`, merge → remove
it) without asking each time. It is required, not optional.

### Implementation-flow extras (beyond CONTRIBUTING.md)

When the user says "implement issue #N", `CONTRIBUTING.md` covers the branch → commit → PR loop. Additional agent-specific steps:

1. **Verify server support first.** Before branching, check the server code (a club_server checkout) to confirm the server actually supports the expected behavior — even if the issue claims it does. Inspect the relevant endpoint's request schema, service logic, and DB model. If the server doesn't support the feature, file a server issue first and mark this issue `status:blocked`. Do not proceed until the server gap is resolved.
2. **Verify the bug still exists** before writing any fix. If the bug has already been fixed (e.g., by a prior commit), report that and close the issue — do not create a no-op PR.
3. **Check for existing tests** covering the affected code path (both positive and negative cases).
   - If tests exist, confirm they pass and exercise the fixed behavior after the change.
   - If no tests exist for the specific issue, **write tests first** (TDD red-green): a failing test that reproduces the bug, then implement the fix.
   - **Tag new tests with the issue number.** The test name (string passed to `test(...)` / `testWidgets(...)` / `group(...)`) must start with `Issue N:` — e.g. `test('Issue 177: group.member_added routes regular members to my-groups', ...)`. Makes regression coverage trivial to find with `grep -r "Issue 177:"`. Applies to tests *added* in the PR; do not retroactively rename pre-existing tests.
4. **Check for skipped tests.** Search for `skip:` annotations referencing this issue number or the affected feature. Attempt to un-skip before committing. If they cannot be un-skipped (e.g., blocked on server work), document why in the PR.
5. **Document test evidence.** In the commit message or PR body, list the specific test names and file paths that confirm this issue is resolved.
6. **Use `git add` with specific files**, not `git add -A`.
7. **Commit/PR conventions:** Commit messages, PR titles, and PR descriptions must describe **what the change does**, not what it deliberately avoids. Do not mention rejected alternatives, deferred phases, or "this does not use X" disclaimers in commit metadata. The one legitimate place for rejected alternatives is the **"Alternatives considered"** field of the feature-request issue template.

### Merge command

When the user authorizes a merge, the **choice between `--squash` and `--rebase` is a human decision** — Claude must always pause and ask, even if squash is the obvious default. Do not assume; the right answer depends on whether the PR's individual commits are worth preserving on the target branch (rebase) or are just work-in-progress noise (squash).

```bash
gh pr merge <num> --squash    # collapse to one commit (default)
gh pr merge <num> --rebase    # replay each PR commit as its own
```

- **Never `--merge`** — the repo setting now blocks it; merge commits caused the PR #591 ancestry-leak from `dev` into `release`.
- **Never `--delete-branch`** — feature branches stay on the remote for archaeology.

After the merge succeeds, clear the status label: `gh issue edit N --remove-label "status:in-progress"`.

---

## Flutter SDK

Flutter is not pinned here: use the `flutter` / `dart` on `PATH`. If `pubspec.lock` shows unexpected transitive-dep changes (notably `matcher` / `test_api`), a different SDK version produced them — check `flutter --version` before committing.

## Dependency versioning

All direct dependencies in every `pubspec.yaml` are pinned to **exact versions** (no caret, no `any`, no `>=` ranges except `environment.sdk` and `environment.flutter`). Transitive deps are locked by `pubspec.lock`. Upgrades happen deliberately — never as a side-effect of `pub get` / `pub upgrade`.

If a `pub get` produces unexpected version changes in `pubspec.lock`, that's a signal the local SDK or constraint is off — investigate before committing.

## Lint baseline

Every module ships its own `analysis_options.yaml` matching the workspace-wide strict baseline. Before pushing a branch or cutting a release, run the `lint-baseline-check` agent (`.claude/agents/lint-baseline-check.md`) to verify no module has drifted — the agent owns the canonical baseline and the rules around when divergence is allowed (e.g. nested options under `test/` and `integration_test/`).

## Development Commands

The `justfile` is the task runner — a thin root that imports purpose-specific
modules (`justfile_<name>.just`), grouped in `just --list`. **Requires just ≥ 1.27**
(for the `[group(...)]` attribute). `just --list` shows the full grouped menu.

```bash
# Analyze a specific module
cd <module> && dart analyze

# Analyze all modules
for d in cl_*/ ui_lib/ cl_club_app/example/ cl_club_website/example/; do
  echo "=== $d ===" && (cd "$d" && dart analyze)
done

# Tests (run from the repo root)
just unit-test-all                 # every package's and both examples' unit + widget tests (no server)
just unit-test <pkg>               # one package's tests, e.g. just unit-test cl_club_members
just app-test                      # UI integration suite (cl_club_app/example), once per server conf
just app-test-one <conf> <file>    # one UI integration file against one conf
```

### Isolated test server

Every server-backed test recipe spins up its **own** fully isolated stack:
`background_server.sh` (native_deploy, cloned by the recipe from
`cloudonlanapps/native_deploy` into the gitignored `.native_deploy/` and pulled
on every run) picks free ports, starts a fresh
postgres + API server in a tmux session, prints its connection JSON, and the
recipe tears it down on exit (`background_server.sh … cleanup`). There is **no shared
default stack to collide on**, so these recipes are safe to run concurrently
(parallel agents, worktrees). Pass `keep=1` to leave the server up for
debugging (then `just stop-app-test-server <server_port> <db_port> <conf>`).

**Testing rule:** Before committing, run the relevant suites — `just unit-test-all`
for package tests and `just app-test` for UI integration (both confs). SDK changes are made and tested in `cloudonlanapps/club_sdk`
(`just test` there). Each runs serially against its
own isolated server.

**Module-specific test guides:**
- SDK (`club_sdk_2`) integration tests: `CLAUDE.md` in `cloudonlanapps/club_sdk` (the workspace's `packages/club_sdk`) — `just test` / `just test-one <file>`, self-contained-fixture rules, delete-lifecycle testing.
- UI integration tests: [`cl_club_app/example/CLAUDE.md`](cl_club_app/example/CLAUDE.md) — the suite lives in `cl_club_app/example/integration_test/` and runs on the Linux desktop once per server conf (`app_test_server1.conf` with the optional modules off and a default country code, `app_test_server2.conf` with the modules on and no default country code); expectations come from `/v1/capabilities`, never from the club; naming/cleanup rules, off-screen-widget pitfalls, provider-read patterns.

## Form Design Guidelines

1. **Let the form framework own the state.** ShadForm tracks all field values via `id`-based registration. Do not create a separate buffer/data class to duplicate form state.

2. **One field = one input.** The form data shape must mirror the UI, not the backend model. If the UI has 3 inputs (e.g., emergency contact name, relation, phone), the form has 3 fields with 3 IDs — never pack multiple inputs into a single field.

3. **Only carry what the form edits.** If a field isn't rendered in the form (server-computed fields, read-only status, etc.), it doesn't belong in the form's data.

4. **Use ShadForm-integrated field types.** Use `ShadSelectFormField`, `ShadSwitchFormField`, etc. instead of standalone widgets with manual `setState`. Every field participates in `ShadForm.value` via its `id`. **For date inputs, default to `CLDatePickerFormField` from `cl_calendar`** rather than `ShadDatePickerFormField` — `cl_calendar` is the project's shared calendar/picker layer and keeps locale/format behavior consistent across features. For time inputs, continue using `ShadTimePicker` (see #11, #12) until `cl_calendar` ships an equivalent. Existing screens still on `ShadDatePickerFormField` are migrated opportunistically, not in bulk.

5. **Validation in static helpers, not in `build()`.** Define validators as static methods in a helpers class (e.g., `UserFormValidators.phone`). Reference them from each field's `validator:` parameter. Reuse across forms.

6. **Set keyboard types on every text field.** Phone → `TextInputType.phone`, email → `emailAddress`, pincode → `number`, names → `name`, address → `streetAddress`. Small effort, big mobile UX impact.

7. **Translate at the boundary, not in the form.** The form speaks flat UI fields and form-local value types. The SDK speaks typed domain models. An adapter layer bridges them — merging, assembling, denormalizing (`''` → `null`). The form never imports domain model classes for assembly. The shared forms in `cl_club_forms` are SDK-free precedents: `SignupForm` and `UserForm` both live in `cl_club_forms` (zero `club_sdk_2` dependency), expose form-local types (`SignupGender`, `FormAddress`), and leave SDK ↔ form adaptation to the caller (e.g. `cl_club_members` `user_form_helpers.dart`, `cl_member_auth` `signup_view.dart`).

8. **isDirty from the framework.** Compare `ShadForm.initialValue` vs `ShadForm.value` using `mapEquals`. Normalize initial values (`null` → `''` for text fields) so comparison works cleanly. A form overrides `isDirty` when comparing the two maps would give the wrong answer: a composite field registers its inner inputs under generated ids; a value is a list; a field is not part of what is saved; or two values count as the same for the form though they are not equal (the same day, blank text and no value). The override says which in its doc comment.

9. **Form-local values in, map out.** A shared form accepts a form-local `Map<String, dynamic>` of initial values (built by the caller's adapter from the domain model) and returns `Map<String, dynamic>` on submit. Adapter helpers — not the form — translate to and from SDK calls. The parameter is `initialValues`, keyed by the form's field-id constants. Two kinds of form take something else: a form of one composite field takes that field's value as a typed `initialValue` (`CampScheduleForm`, `OneOffScheduleForm`, `ProgrammeScheduleAdjustForm`), and a form of one field takes its value (`RenameForm`, a `String`). What a form chooses among is not an initial value (`EventTimetableForm`'s `schedules` and `initialScheduleIndex`).

10. **Custom fields via `ShadFormBuilderField<T>`.** When neither a ShadForm-integrated field nor a `cl_calendar` picker fits (e.g., DOB needs a year-friendly picker), create a custom widget extending `ShadFormBuilderField<T>`. Call `didChange(value)` on user interaction. Drop in with an `id` — zero changes to the rest of the form. Reach for this only after confirming `cl_calendar` doesn't already cover the input type; the shared picker layer is the preferred home for any date/calendar-shaped control.

11. **Pre-seed controller fields the user shouldn't have to fill.** Some pickers (notably `ShadTimePicker`) refuse to fire `onChanged` until **every** controller field is non-null — including columns the form has hidden. When `showSeconds: false` (or any other column suppressed), pass an explicit controller with `second: 0`, `minute: 0`, etc. so the picker emits a value as soon as the user fills the columns that *are* visible. Otherwise the form's value stays null forever and validators report "required" no matter how many times the user re-edits.

12. **Prefer the 24-hour `ShadTimePicker` over the `.period` variant** for any time that round-trips through storage. `.period` returns `hour` in 1-12 with `period` set separately; converting both ways is error-prone (silent overlap-detection failures, "13 AM" gibberish on re-render). The default 24-hour picker keeps `hour` as 0-23 directly, so storage and display agree.

13. **Label every field with `LabeledFormRow`, the label stacked above the field, even on wide layouts.** It is the one way a form labels a field, composite fields included (`cl_club_forms` `widgets/form/`): it decides the label's style, marks a required field (`required: true`) and sets the gap to the field. A field does not use its own `label:`. Inline labels never line up cleanly when adjacent controls have heterogeneous widths (date picker, time picker, plain input); one stacked pattern reads cleanly on every viewport.

14. **Gaps come from `FormSpacing`, through `Column.spacing`.** A form stacks its rows in a `FormBody`, which applies `FormSpacing.rowGap`; a group of rows is set off with `FormSpacing.sectionGap`; `LabeledFormRow` applies `FormSpacing.labelGap`. No number in a form's `spacing:`, and no interleaved `SizedBox(height: N)` between rows. One source for every form, so the gaps cannot drift apart.

15. **Two-column form grids must collapse to a single column on narrow surfaces** via `LayoutBuilder`. Pixel-perfect alignment between unrelated controls inside a 2-column layout is unattainable on mobile widths.

16. **Self-contained feature folders may duplicate tiny generic helpers.** When a multi-file feature (e.g. `events_editor/event_schedule/`) only consumes a small generic helper such as `ReadOnlyField`, copying it into the feature folder is acceptable so the folder ships as a self-contained unit. The original stays at `widgets/` root for its other consumers — duplication only makes sense for small, stable helpers; promote to a shared location if it grows.

17. **Every `ShadForm` lives in `cl_club_forms`; its dialog/screen lives in the feature package.** (Evaluation's four forms are the exception: they stay in `ui_lib` with the rest of evaluation's UI, whose models they share.) `cl_club_forms` and `ui_lib` do not depend on each other; a feature package uses both. A form is a pure-UI widget — SDK-free, no Riverpod — that speaks flat form values and form-local types (`SignupGender`, `GroupMode`, `GroupGender`, `FormAddress`, …) and exposes its field-id constants. It never imports `club_sdk_2`. The consuming package hosts it: a connected view/screen wires providers + the SDK call, and any **dialog is built in the feature** (`showShadDialog` wrapping the form), never in `cl_club_forms`. This keeps a form reusable outside a dialog. Precedents: `SignupForm`/`SignupView`, `LoginForm`/`LoginView`, `ChangePasswordForm`/`ChangePasswordView`, plus the SDK-free `RenameForm`, `LocationEditForm`, `VenueCreateForm`, `GroupCreateForm`, `GroupEligibilityForm`, and the `UserPersonalDetailsForm`/`UserContactForm`/`UserAddressForm` section editors.

18. **One adapter per form, in the consuming package, with consistent names.** The SDK ↔ form boundary is a single adapter mirroring the form's flat `Map<String, dynamic>`:
    - `build<X>FormInitialValues(SdkModel?)` → `Map` — SDK → form (`null` = create defaults).
    - `<X>FormSubmit.create({values, notifier})` / `.update({values, …})` — form → SDK. Section editors get partial `update<Section>(...)` methods that send **only** their fields (others left untouched). Name the section method after the section it edits (`updatePersonalDetails`, `updateContact`, `updateAddress`, `updateEligibility`, `updateLocation`, …) — **even when an entity has exactly one editable section**, so the name reads as a partial and never collides with a full `update`.
    - `<X>FormValidators` — pure validators, in `cl_club_forms` next to the form. A rename dialog reuses the same `<X>FormValidators.name`; do not re-implement the rule inline.
    - **No exceptions for small forms.** Every section form routes through this adapter — there is no shortcut for a two-field form (e.g. `LocationEditForm`). The connected card must never call a notifier mutation directly; it goes through `<X>FormSubmit.update<Section>`.
    See `cl_club_members/lib/src/models/{user,group}_form_helpers.dart` and `cl_club_venues/lib/src/models/venue_form_helpers.dart`.

19. **Create uses one full form; editing is section-by-section — never a separate edit route.** A `<X>CreateForm` gathers everything for creation. Editing an existing entity happens in place on its profile/detail view: each section (rename, eligibility, location, address, contact, …) has its own small editor opened in a dialog, calling a partial-update adapter method. There is **no `/…/:id/edit` route** for any entity — venues, groups, and users all edit section-by-section.

20. **One contract: the host drives the form through a `GlobalKey<XFormState>`; the form owns no title, no buttons, no dialog and no width of its own.** Every form's state mixes in `FormContract` (`cl_club_forms` `widgets/form/`), which gives the host:
    - `validate()` — the form's values as a `Map<String, dynamic>`, or `null` when invalid. A section editor returns its section's partial map.
    - `isDirty` — whether anything changed (rule 8). It drives the discard prompt of a create view via `PopScope`, and lets an unmodified Save be a no-op.
    - `showErrors(fieldErrors, formError)` — what the server refused, put back on the fields by id and inline.
    - `enabled` — a parameter of the widget; the host turns it off while it saves. The form passes it to every field: a field given none (a `const` one above all) is not built again when the form is turned off, and stays drawn live.

    The host's Save action calls `validate()`, runs the save itself, holds the in-flight state, and calls `showErrors` when the server refuses a value. A form has no `onSubmit` callback, no `handleSubmit()` and no `isSubmitting`. Cross-field rules (age band, password match, "at least one name", an auto/semi-auto group needs ≥1 criterion) are the form's `crossFieldError` and surface as an **inline form-level message** (`validate()` returns `null`), never a toast from inside the form. A form that wants Enter to submit takes a plain `onSubmitted` callback, which the host points at its Save action.

    **A refused save shows in one of three places, by what it is about** (#97):
    - what the server refuses about a field shows on that field (`showErrors(fieldErrors:)`);
    - what it refuses about the form as a whole shows inline in the form (`showErrors(formError:)`);
    - a toast is for a failure that is not about what was typed: the network, the server being down, an unexpected error.

    The form's adapter says which (rule 18): `<X>FormSubmit.fieldErrorsFor(error)`, or a `...Refusal(error)` that gives the field messages and the form-level one. Empty or `null` means the failure is about nothing the form holds, and the host toasts a fixed message; the raw error is never shown. After any failure the form is on again, with its buttons, and keeps what was typed. A form-level message goes on the next edit of the form: `FormContract` does that, so no form clears it from its own `onChanged`. Once the form is on again it puts the focus on the first refused field, or back where the cursor was (#93); the host does nothing for that.

21. **A section editor sends only its own fields.** Its adapter method (`update<Section>`) passes a SDK `ValueGetter` *only* for the fields that section edits — the SDK treats a `null` getter as "no change". Never reuse the full-form `update` for a section, or the omitted fields get cleared on the server. Protected fields (date of birth, gender) are gated by `canEdit*` flags **and** omitted from the returned map when not editable, so the server's protected-field guard isn't tripped.

22. **A form, or a control that saves on its own: never both in one widget.** A control may save directly only when its value is complete after one interaction and needs no check against another field: a toggle, a rating, a picked file. Everything else is a field of a form, and reaches the server only after `validate()`. A group of controls that each save on their own is not a form, whatever its layout, and is not named one (`IdentityDocumentsUploader`, `EvaluationFillBody`). When an action needs both — files and a consent, answers and a completeness check — the host arranges the direct-save widget and the form side by side and gates the action on both.

23. **Field ids are named constants.** Each form has a `<X>FormFields` class of `static const String` ids (`EventCreateFormFields.titleId`); the form, its adapter and its tests use them. No bare string id.

## Section-wise Editors (shared inline pattern)

Editing an existing entity happens **section-by-section, inline, in place** — never via a dialog/popover and never via a `/…/:id/edit` route. All section editors are built on one shared, SDK-free primitive in `ui_lib`; do not hand-roll the chrome, the edit pencil, or a dialog host per feature.

1. **Use `EditableSectionCard<T>` for every structured section.** It is the canonical chrome (a titled `ShadCard`) and owns the read↔edit toggle, validation gating, no-op detection, and the in-flight saving state. The host supplies: read-mode content (`read`), the inline form (`editBuilder`, a `Widget Function({required bool enabled})` built only while editing so its `GlobalKey` attaches only in edit mode; it receives the card's saving state as `enabled`, false while a save is in flight, and the host passes it to its form), `onValidate` (reads the form's state → partial value or `null`), `isDirty`, and `onSave(value) → Future<bool>`. `T` is the form's `validate()` return type: `Map<String, dynamic>`, for every form (rule 20). A section whose form can be emptied may also pass `onClear` and `canClear`: the card then shows a Clear action beside Cancel and Save in edit mode while `canClear()` is true. It empties the host's form; nothing is stored until Save.

2. **The form is the SDK-free `cl_club_forms` widget; the SDK call lives in the host.** `EditableSectionCard` (in `ui_lib`) and the section forms (`UserPersonalDetailsForm`, `UserContactForm`, `UserAddressForm`, `GroupEligibilityForm`, `LocationEditForm`, …) never import `club_sdk_2`. The connected card (a `ConsumerStatefulWidget` in the feature package — e.g. `PersonalDetailsCard`, `GroupEligibilitySection`, `VenueLocationCard`) holds the `GlobalKey`, calls the `update<Section>` adapter inside `onSave`, shows the toast, invalidates providers, and returns `true`/`false`. Returning `false` keeps the card in edit mode for a retry.

3. **No-op via the form's `isDirty`.** Every section form exposes `bool get isDirty` (compare `ShadForm.initialValue`/seeded initial values vs current value, à la `UserForm`/`GroupCreateForm`). Wire it to `EditableSectionCard.isDirty`; an unmodified Save then just closes the editor without an SDK call (rule 20).

4. **The edit affordance is `SectionEditButton` — shown only when the viewer may edit.** It is a `GestureDetector`-based pencil (no Material `InkWell`/`InkResponse`, no tooltip overlay — see issue 473). Pass `canEdit` (computed from the viewer's roles/relationship); `EditableSectionCard` hides the pencil when it is false. Don't render an affordance the user can't use, and don't gate by accepting a nullable `onEdit` callback from the host — compute `canEdit` and pass the data in. **An empty section** (`isEmpty: true`) is hidden **entirely** from a read-only viewer (nothing to show, nothing to add); an editor still sees it with the tap-to-add hint so they can introduce the section.

5. **Toasts are section-specific; errors never leak exceptions.** Success messages name the section (`'Location updated.'`, not a generic `'Profile updated.'`). On failure show a fixed, friendly message (handle `ServerException` codes where useful) — never interpolate the raw `$e` into the toast.

6. **Three deliberate exceptions stay non-inline.** (a) **Rename** is a management-section button → `showShadDialog` hosting `RenameForm` (the norm; `TitleRow` is never made editable). (b) **Checkbox/toggle sections** (e.g. venue flags) persist immediately on change and, when the viewer lacks permission, render **disabled** showing the current value rather than hiding. (c) **Markdown** (bio, description) keeps using `EditableMarkdown`.

## UI Style Guidelines

- **Avoid color coding.** Do not use colored badges, chips, or color-differentiated status indicators. Use plain text, muted borders, and monochrome styling instead. Color draws unnecessary attention and looks cluttered at scale.
- **Avoid chip-like badges.** Do not use colored background containers as status tags. Prefer inline text with subtle border outlines when a visual code is needed (e.g., a bordered letter code like `[P]` rather than a green pill badge).
- **Keep cards clean and spacious.** Use bordered cards with rounded corners and comfortable padding. Separate items with thin dividers, not dense stacking.
