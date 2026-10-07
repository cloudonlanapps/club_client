# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`cl_member_auth` is a standalone, GoRouter-free authentication library for the club Flutter app ecosystem. It provides callback-driven auth views, Riverpod providers for auth state, and session persistence. It is consumed by `cl_users`, `cl_member_zone`, and the main `app`.

## Development Commands

```bash
# Get dependencies
flutter pub get

# Analyze code
dart analyze

# Run the example app (Navigator-based, no GoRouter)
cd example && flutter run -d chrome
```

## Architecture

### Package Structure

- `lib/` - The reusable `cl_member_auth` package
- `example/` - Minimal Flutter app demonstrating usage without GoRouter

### Key Dependencies

- **cl_server_config** (`../cl_server_config`) - Centralized server configuration (`serverConfigProvider`, `ServerConfig`)
- **club_sdk_2** (git: `cloudonlanapps/club_sdk`) - SDK providing `SecureClient`, `AuthSource`, `UserPrivate`, `AuthToken`, and exception types
- **flutter_riverpod** - State management (all auth state flows through Riverpod)
- **shadcn_ui** - UI components (forms, cards, buttons, toasts). Theme-neutral: all styling comes from `ShadTheme.of(context)`, no hardcoded colors/fonts
- **shared_preferences** - Session token persistence
- **ui_lib** (`../ui_lib`) - Hosts the pure-UI `SignupView` and `UsernameAvailabilityField`. `SignupScreen` here wires the SDK-bound defaults (provider-based username check, `client.auth.register` + `ServerException`→`SignupFailureException` translation) around the view.

Does **not** depend on: `go_router`, `meta`.

### Folder Conventions (lib/src/)

- `models/` - Data classes (`AuthSession`)
- `providers/` - Riverpod providers and notifiers
- `widgets/` - All UI components (views, forms, internal widgets)

### No Scaffold Convention

Views (`LoginView`, `SignupView`, `ForgotPasswordView`, `ChangePasswordView`) return content body only — no `Scaffold`, no `AppBar`. The consuming app wraps them in its own Scaffold/shell. This allows the same view to be used in a full-screen route, a dialog, or a popover.

## Exported API

### Providers

| Provider | Type | Purpose |
|----------|------|---------|
| `serverConfigProvider` | `Provider<ServerConfig>` | Re-exported from `cl_server_config`. Must be overridden in `ProviderScope` with API base URL |
| `authStateProvider` | `AsyncNotifierProvider<AuthNotifier, UserPrivate?>` | Central auth state. `null` = logged out, `UserPrivate` = logged in, `AsyncError` = status blocker |
| `clientProvider` | `AsyncNotifierProvider<ClientNotifier, SecureClient>` | Authenticated SDK client, auto-configured from stored session |
| `tokenStorageProvider` | `Provider<TokenStorage>` | SharedPreferences-backed session persistence |

### AuthNotifier Actions

| Method | Purpose |
|--------|---------|
| `login(username, password)` | Authenticate, store session, fetch user profile, check status |
| `logout()` | Server logout (fire-and-forget), clear local session |
| `changePassword(currentPassword, newPassword)` | Change password for logged-in user |
| `resetPassword(email)` | Request a self-service password reset; server emails a new password if the address matches a member (uniform response, no existence disclosure) |
| `deleteSelf()` | Soft-delete account then logout |
| `restoreFromStoredSession()` | Called on app startup to resume session |
| `checkStatus(user)` | Throws `AccountPendingException`, `AccountBlockedException`, or `UserNotFoundException` for non-active users |

### Role Getters on AuthNotifier

`isLoggedIn`, `isAdmin`, `isSuperAdmin`, `isCoach` - derived from current `UserPrivate` state.

### Views (no Scaffold)

| Widget | Required Callbacks | Optional Action Override |
|--------|-------------------|------------------------|
| `LoginView` | `onLoginSuccess(UserPrivate)`, `onNavigateToForgotPassword()`, `onNavigateToSignup()` | `onLogin(username, password)` |
| `SignupView` | `onSignupSuccess()`, `onNavigateToLogin()` | `onSignup(username, email, password, name, phone?)` |
| `ChangePasswordView` | `onSuccess()`, `onCancel()` | `onChangePassword(currentPassword, newPassword)` |
| `ForgotPasswordView` | `onNavigateToLogin()` | `onResetPassword(email)` |

The pure-UI forms behind these connected views live in `cl_club_forms` (`LoginForm`,
`ChangePasswordForm`, `SignupForm`, `ForgotPasswordForm`) — SDK-free,
callback-driven. The views here wire them to `authStateProvider` and translate
SDK errors. Self-service password reset calls
`authStateProvider.notifier.resetPassword(email)`; the server always returns
the same response regardless of whether the email matches a member, so
`ForgotPasswordView` shows a speculative confirmation that never reveals
account existence.

### Callback Pattern

Navigation callbacks are **required** (the library cannot navigate without a router). Action callbacks are **optional** — if omitted, the view calls the notifier's action directly. If provided, the consumer can wrap/extend the default behavior:

```dart
LoginView(
  onLoginSuccess: (_) => context.go('/memberzone'),
  onNavigateToForgotPassword: () => context.go('/auth/forgot-password'),
  onNavigateToSignup: () => context.go('/auth/signup'),
  // Optional: wrap default login with analytics
  onLogin: (username, password) async {
    analytics.track('login_attempt');
    await ref.read(authStateProvider.notifier).login(username, password);
  },
)
```

### Internal Widgets (not exported)

- `AccountPendingView` - "Awaiting approval" status card
- `AccountBlockedView` - "Account blocked" status card
- `AccountLeftView` - "Account inactive" status card
- `LoadingIndicator` - Centered spinner with optional message

### Models

- `AuthSession` - Persisted session data (`accessToken`, `expiresAtUtc`, `refreshToken`). This is a persistence concern, not a domain model. Domain types (`UserPrivate`, `AuthToken`, `UserStatus`, etc.) come from `club_sdk_2`.

## Integration

### Host App Setup

```dart
import 'package:cl_server_config/cl_server_config.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        serverConfigProvider.overrideWithValue(
          const ServerConfig(baseUrl: 'https://api.example.com/v1'),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
```

### With GoRouter (app/)

Auth views are placed inside GoRouter routes. The consuming app provides callbacks that call `context.go()`:

```dart
GoRoute(
  path: '/auth/login',
  pageBuilder: (context, state) => buildTransitionPage(
    child: LoginView(
      onLoginSuccess: (_) => context.go('/memberzone'),
      onNavigateToForgotPassword: () => context.go('/auth/forgot-password'),
      onNavigateToSignup: () => context.go('/auth/signup'),
    ),
  ),
),
```

Router redirect guards watch `authStateProvider` for route protection.

### Without GoRouter (example app)

Use `Navigator.push` in callbacks, and an `AuthGate` widget that watches `authStateProvider` to switch between login and authenticated views.

### Consumer Libraries

- **cl_users** - Depends on `cl_member_auth` for auth. Re-exports auth symbols for backward compatibility. Provides `ProfileScreen`, `AdminGuard`, and admin user management screens.
- **cl_member_zone** - Depends on `cl_member_auth` for auth. Re-exports auth symbols. Provides member dashboard screens, domain providers (events, enrollments, etc.) that use `clientProvider`.

## Local Storage

### What is Stored

Only `AuthSession` — a JSON string in `shared_preferences` under key `'cl_member_auth.session'`:
- `accessToken` - Opaque JWT bearer token (not the user's password)
- `expiresAtUtc` - Token expiry timestamp
- `refreshToken` - Optional token for renewal

### What is NOT Stored

No passwords, no usernames, no login history. The token is the only persisted credential.

### Security

`shared_preferences` is **not encrypted**:
- iOS: `NSUserDefaults` (plain text, app sandbox)
- Android: `SharedPreferences` (XML, app sandbox)
- Web: `localStorage` (accessible to same-origin scripts)

Adequate for session tokens in a club app context. Not suitable for secrets or credentials.

### Clearing Storage

- `authStateProvider.notifier.logout()` - Primary mechanism (also calls server logout)
- `authStateProvider.notifier.deleteSelf()` - Deletes account + clears storage
- Auto-cleared on: token expiry at startup, non-active account status (pending/blocked/left)

### Auth State Flow

```
App Start
  |
  v
restoreFromStoredSession()
  |
  +--> No session / expired --> return null (logged out)
  |
  +--> Valid session --> getCurrentUser()
         |
         +--> Status: active  --> return UserPrivate (logged in)
         +--> Status: pending --> clear token, throw AccountPendingException
         +--> Status: blocked --> clear token, throw AccountBlockedException
         +--> Status: left    --> clear token, throw UserNotFoundException
         +--> Network/auth error --> clear token, return null
```

## Status Handling

Non-active user statuses are surfaced as exceptions in `authStateProvider`'s `AsyncError` state. `LoginView` catches these and renders internal status cards:
- `AccountPendingException` --> "Awaiting approval" card with "Back to sign in" button
- `AccountBlockedException` --> "Account blocked" card
- `UserNotFoundException` --> "Account inactive" card

The "Back to sign in" button calls `ref.invalidate(authStateProvider)` to reset to login form.

## Future Enhancements

### Login History / Account Switcher
Currently only the most recent session is stored. Could maintain a list of previously authenticated usernames (not passwords) to support:
- Quick account switching for families sharing a device
- "Last signed in as..." display on the login screen
- Auto-fill username from history

### Encrypted Storage
Replace `shared_preferences` with `flutter_secure_storage` for token persistence:
- iOS: Keychain (hardware-backed encryption)
- Android: EncryptedSharedPreferences (AES-256)
- Web: No equivalent — would need a different strategy (HttpOnly cookies, session-only storage)

### Biometric Authentication
Use `local_auth` package to gate session restore behind fingerprint/face recognition:
- On app startup, if a valid session exists, prompt biometric before restoring
- Configurable: users can opt in/out from settings
- Fallback to PIN/password if biometric unavailable

### Browser Credential Management
On web, integrate with the browser's Credential Management API:
- `navigator.credentials.store()` after successful login for browser password manager integration
- `navigator.credentials.get()` on login screen to auto-fill from saved credentials
- Enables "Save password?" browser prompts

### Token Refresh
The `AuthSession` model already stores `refreshToken`. The SDK's `AuthSource` interface has `refreshToken()`. Currently unused — tokens simply expire and the user re-authenticates. Implementing automatic refresh would:
- Call `refreshToken()` before the access token expires
- Update the stored session with new tokens
- Avoid forcing re-login for long-lived sessions

### Remember Me / Stay Signed In
Add an opt-in "Remember me" toggle on the login form:
- When enabled: persist session as today (survives app restart)
- When disabled: store session in memory only (cleared on app close)
- Useful for shared/public devices where users don't want sessions to persist

### Session Timeout / Idle Lock
For security-sensitive deployments:
- Track last user interaction timestamp
- After configurable idle period, lock the app and require re-authentication
- Could combine with biometric unlock for convenience
