# cl_club_app/example — the UI integration suite

A neutral club app ("Example Club") over club_core: `lib/main.dart` calls
`clubMain()`, and `assets/` holds a club.json, logo and contact details that
name no real club. It exists to host the UI integration suite in
`integration_test/`, which tests club_core's packages end to end against a
real, isolated club_server. The club apps keep only a smoke test each.

## Running

From the club_core root (`justfile_app_tests.just`):

```bash
just app-test                                   # whole suite, once per conf
just app-test app_test_server2.conf             # whole suite, one conf
just app-test-one app_test_server1.conf workflow1_password_reset_by_user_test.dart
just app-test-one app_test_server1.conf <file> keep=1   # leave the server up
```

Each run starts its own stack with `background_server.sh <conf> start
--auto-ports` (native_deploy, cloned by the recipe into the repo root's
gitignored `.native_deploy/`): free ports, a fresh run directory, a
fresh database, torn down on exit. It never touches the dev, beta or prod
stacks, so there is nothing to ask permission about. Runs are Linux desktop
(`flutter test -d linux`); a web target is club_core#89.

## The server confs

At the club_core root, one per real deployment shape, named without the club:

| Conf | Credits, evaluations, event marketing | Identity verification | Default country code |
|---|---|---|---|
| `app_test_server1.conf` | off | on | `44` |
| `app_test_server2.conf` | on | off | unset (the apps fall back to `91`) |

Between them the two confs cover both settings of every optional module, and a
server that reports a default country code and one that reports none (#31);
keep them in step with the deployments they stand for. Both clone club_server's `main` from git. To test against a
local server checkout, set `source` to its path, relative to the conf.

The example's `club.json` runs camps, programmes and one-off events
(`eventTypes`, #115 #122), so the suite covers every staff event list.

## Expect from capabilities, never from the club

A test decides what to expect from `GET /v1/capabilities`, read once in
`setUpAll` with `stackCapabilities` (`_helpers/capabilities.dart`). No test
branches on club name or product. A case that does not apply to this stack
skips itself with a reason, so the run says so instead of passing without
asserting anything:

```dart
if (skipUnless(enabled: caps.creditSystem, feature: 'credit system')) return;
if (skipIf(enabled: caps.identityVerification, feature: 'identity verification')) return;
```

A phone typed without a country code is stored with the stack's: expect
`storedPhone(caps, '9876543210')`, never a literal `+91…` (#31).

A known, open failure skips at the point it would fail, citing its issue,
with `skipKnownFailure(issue: N, what: …)`. Remove the skip with the fix.

## Club neutrality

club_core names no club. Fixtures use invented names (never real-looking
people), and comments cite club_core or club_server issues, never an app's.

## Writing tests

### Naming convention

Each file owns a workflow identifier, a number or a short slug (`grp`), and
every resource it creates carries it as a prefix:

| Item | Pattern |
|---|---|
| Test file | `workflow<id>_<short_description>_test.dart` |
| Test name | a sentence describing the workflow |
| Resources (users, events, venues, groups, …) | `workflow<id>_user`, `workflow<id>_event`, … |

Fixtures then cannot collide, and any leftover row names the test that made it.

### Dates

Never a fixed future date: the server refuses anything past its 52-week
scheduling horizon. Date fixtures relative to now (e.g. midnight UTC 30 days
ahead, plus hours).

### Cleanup

Every test cleans up what it creates through the matching destructive UI
(e.g. soft-delete a user from the admin profile), as a real assertion. The
database is fresh per run, but the cleanup flow gets coverage and the test
stays correct against a server that was not reset.

### Drive through the user-facing path

Reach a screen the way a user does: navigate to a parent and tap the
affordance. The only legitimate `go()` sets a workflow's starting point
(`go('/auth/login')`, `go('/memberzone/profile')`). Deep-linking skips the
entry button and the permission check that gates it, so a test can pass while
the real path is broken.

### Reading provider state

Read the provider the mounted tree is watching. For the logged-in user, read
`authStateProvider.valueOrNull`. For another user, first open a screen that
watches `clUserPrivateProvider(username)`, then read it. Never
`container.read(someAutoDisposeFamily(x).future)` with nothing watching it:
the provider disposes, the future never resolves, and the test hangs.

The same holds for polling `container.read(provider)` in a `waitFor`: if no
screen watches that exact key, each read builds the provider and drops it,
and it never resolves. Hold it for the test with
`container(tester).listen(provider, (_, _) {})` (close it in `addTearDown`).
Whether a screen happens to watch it can depend on the time of day — the
dashboard only shows today's events — which is how #107 and #109 hid.

### Off-screen widgets

The Linux test window is 1280×720, so lower fields and buttons fall below
the fold, where a synthesized `tester.tap` or `enterText` silently misses.

- Buttons: invoke `onPressed` directly — `invokeShadButton` and
  `submitFormContaining` in `_helpers/forms.dart`, or a card's own `onTap`.
- Long forms: scroll the field into view with `tester.scrollUntilVisible`
  before `enterText`; as a fallback, `tester.binding.setSurfaceSize` (restore
  it in `addTearDown`).
- Do **not** use `tester.ensureVisible`: it interacts badly with continuous
  animation pumping and can hang.
