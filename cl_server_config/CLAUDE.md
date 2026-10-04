# cl_server_config

Centralized server configuration and network status detection for the club app
ecosystem.

**Master providers do not live here.** They live in `cl_remote_store` — see
[`cl_remote_store/lib/cl_remote_store.dart`](../cl_remote_store/lib/cl_remote_store.dart)
for the canonical export list and [`docs/master_providers.md`](docs/master_providers.md)
for the cross-package inventory.

## Quick Reference

- **Language**: Dart / Flutter
- **Package**: `cl_server_config`
- **Dependencies**: `flutter_riverpod`, `http`, `shadcn_ui` — **no `club_sdk_2`**; this package makes no SDK calls and references no SDK types
- **Linting**: `very_good_analysis` (^10.0.0)
- **Main branch**: `dev`

## Build & Test Commands

```bash
dart pub get
dart analyze
flutter test
```

## What This Package Ships

```
lib/
  cl_server_config.dart         # Barrel export
  src/
    extensions/
      date_time_format.dart     # DateTimeFormat
    models/
      server_config.dart        # ServerConfig (base URL)
    providers/
      config.dart               # serverConfigProvider, apiBaseUrlProvider
      network_status.dart       # networkStatusProvider, NetworkStatus(Notifier)
    widgets/
      network_failure_screen.dart
      network_status_wrapper.dart
```

That is the full surface area. There are no domain master providers
(users, events, venues, groups, enrollments, attendance, notifications,
pending actions, broadcasts, …) defined here. All of those live in
`cl_remote_store`.

## Module Responsibilities

### 1. Server Configuration

- API base URL via `serverConfigProvider` / `apiBaseUrlProvider`.
- Host app overrides `serverConfigProvider` in its `ProviderScope`.
- Never hardcode URLs.

### 2. Network Status

- `networkStatusProvider` — reactive, no background polling.
- Data providers call `checkNow()` on fetch failure, `markOnline()` on success.
- `NetworkStatusWrapper` / `NetworkFailureScreen` for UI.

### 3. SDK Access Boundary

- `secureClientProvider` — the authenticated SDK client — lives in
  `cl_remote_store`, not here. `cl_server_config` makes no SDK calls beyond the
  `/health` ping in `NetworkStatusNotifier`.
- The only modules that call SDK functions are:
  - `cl_member_auth` — auth operations only (login, logout, changePassword,
    getCurrentUser).
  - `cl_remote_store` — every other domain resource, through
    `secureClientProvider`.
- No other module should call SDK functions directly.

## Master Provider Pattern

The pattern itself is described in the workspace root `CLAUDE.md` under
**Centralized Resource State Management**. The current inventory of master,
derived, family, and public providers lives in
[`docs/master_providers.md`](docs/master_providers.md). Code lives in
`cl_remote_store/lib/src/providers/`.

When adding a new master provider:

1. Put the file in `cl_remote_store/lib/src/providers/`, not here.
2. Export it from `cl_remote_store/lib/cl_remote_store.dart`.
3. Update the inventory in [`docs/master_providers.md`](docs/master_providers.md).
