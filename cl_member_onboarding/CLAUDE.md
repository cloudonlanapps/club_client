# cl_member_onboarding

Onboarding zone for users whose status is `registered` or `pending`. Mounted under `/onboarding/**` by `cl_club_app/lib/src/router.dart`; consumed only by `cl_club_app`. Navigation is expressed as callbacks.

## Routes

| Path | Screen | View |
|---|---|---|
| `/onboarding/welcome` | `OnboardingWelcomeScreen` | `OnboardingWelcomeView` |
| `/onboarding/submit-documents` | `OnboardingSubmitDocumentsScreen` | `OnboardingSubmitDocumentsView` |

### `/onboarding/welcome` — three status-driven variants

`OnboardingWelcomeView` renders one of three sub-widgets based on `currentUser`:

- `registered` + empty `adminReviewNote` → `IntroCard` → Continue → `/onboarding/submit-documents`.
- `registered` + non-empty `adminReviewNote` → `ReapplyVariant` (registration fields editable, username pinned, banner shows the admin note) → `reapplyForSelf` → Continue → `/onboarding/submit-documents`.
- `pending` → `SubmittedConfirmation` ("documents submitted, awaiting approval") → Back to sign in (logout).

### `/onboarding/submit-documents`

`OnboardingSubmitDocumentsView` hosts `IdentityDocumentsSubmitBody`, which arranges the step: the intro, `IdentityDocumentsUploader` (from `ui_lib`; each file is saved as it is added or removed, through the `cl_remote_store` master notifiers), `IdentityDocumentsConsentForm` (from `ui_lib`; the privacy checkbox), the **Submit** and **I'll do it later** buttons (`IdentityDocumentsSubmitActions`) and the tips (`IdentityDocumentsUploadTips`). Submit is disabled, with the reason shown, until a document is uploaded; pressing it validates the consent form and then calls `submitForReviewForSelf` and flips status `registered` → `pending`. The router redirect then bounces the user back to `/onboarding/welcome` where the `SubmittedConfirmation` variant renders.

## Screens and shell

Each screen watches `authStateProvider`, evaluates its gate via `onboardingGateAllows`, and renders `ErrorView` (tone: neutral) on failure. The screen then forwards `currentUser` + navigation callbacks to its same-named view. The view is presentational and never watches auth.

`OnboardingShell` wraps both screens via the `ShellRoute` in `cl_club_app/lib/src/router.dart`. It owns the chrome (Scaffold, app bar, footer) and **does not gate** — gating is the screen's job. Active users never reach these routes because the host router redirect bounces them before the shell is mounted.

## Public API (barrel)

`lib/cl_member_onboarding.dart` exports:

- `OnboardingWelcomeScreen`, `OnboardingSubmitDocumentsScreen` — screens, mounted by `cl_club_app/lib/src/router.dart`.
- `OnboardingShell` — shell, used by the `/onboarding/**` `ShellRoute` in `cl_club_app/lib/src/router.dart`.

Views, widgets, providers, and models stay internal.

## Internal structure

```
lib/src/
  models/      - OnboardingGate enum + onboardingGateAllows (per-route gate predicate).
  providers/   - clMyIdentityDocSlotsProvider (composes gallery + orphan uploads).
  screens/     - OnboardingWelcomeScreen, OnboardingSubmitDocumentsScreen
                 (watch authStateProvider, evaluate gate, wrap view).
  views/       - OnboardingWelcomeView (three variants), OnboardingSubmitDocumentsView
                 (presentational; never watch auth).
  widgets/     - OnboardingShell, IntroCard, ReapplyVariant,
                 SubmittedConfirmation, IdentityDocumentsSubmitBody,
                 IdentityDocumentsSubmitActions, IdentityDocumentsUploadTips.
```

## Allowed dependencies

`cl_member_auth`, `cl_remote_store`, `cl_server_config`, `ui_lib`, `club_sdk_2`, `flutter`, `flutter_riverpod`, `shadcn_ui`.

**Forbidden:** `cl_member_zone`, `cl_club_members`, `cl_club_events`, `cl_club_venues`, `cl_calendar`, `go_router`.

## Conventions

This package follows the workspace-wide rules:

- Root [`../CLAUDE.md`](../CLAUDE.md) — auth boundary, SDK boundary, server config, no hardcoded routes, view permission guidelines (including the "views assert preconditions" standard), form rules, UI style.
- [`../docs/coding_rules.md`](../docs/coding_rules.md) — one class per file, no `_`-prefixed declarations in `lib/`, folder conventions, file size limits.
- [`../docs/dart-data-class.md`](../docs/dart-data-class.md) — **N/A**: this package defines no domain data classes.
- [`../docs/package_review_guidelines.md`](../docs/package_review_guidelines.md) — checklist used to audit this package.

## Testing

- **Workflow** (in `app/integration_test/`) — `workflow3_user_profile_updates_test.dart` covers the end-to-end flow (register → submit → pending → admin note → reapply → approve) against the isolated test server; Phase 3b exercises the reconsider/reapply cycle specifically.
- **Widget** (in `test/screens/`, `test/widgets/`) — screen gate cases and welcome-view variant cases.
- **Unit** (in `test/providers/`) — `clMyIdentityDocSlotsProvider` URL resolution.
- **Visual audit** (in `example/`) — demo scenarios switch the dummy user between variants so the three welcome cards and the submit-documents flow can be inspected without a server.

## Example

`example/` is a small Navigator-based Flutter app that mounts `OnboardingShell` + each screen with overridden providers (dummy users, dummy upload state). Run with:

```bash
cd cl_member_onboarding/example && flutter run -d chrome
```

Use the in-app scenario picker to switch between the registered-no-note, registered-with-note, and pending variants.
