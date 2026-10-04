# cl_remote_store — Centralized resource state

Master providers for every mutable domain resource (users, events, venues, groups, enrollments, attendance, notifications, pending actions, broadcasts, …). This module and `cl_member_auth` are the only places that call SDK data functions; see the SDK Access Boundary rule in the workspace-root `CLAUDE.md`.

Full provider inventory: [`../cl_server_config/docs/master_providers.md`](../cl_server_config/docs/master_providers.md).

`secureClientProvider` (`lib/src/providers/client.dart`) — the authenticated SDK
client every master provider reads — is **defined here** and overridden by the
host app with the authenticated client from `cl_member_auth`.

`currentUserProvider` (`lib/src/providers/current_user.dart`) — the logged-in
user, used by master providers to adjust fetch strategy by role — is likewise
**defined here** and overridden by the host app from `authStateProvider`.

## Pattern

1. **Master Notifier per resource.** Each resource has a single `AsyncNotifierProvider` (or `AsyncNotifierProvider.family` for keyed resources like enrollments/attendance) that owns the canonical state and all mutation methods. Only this notifier calls SDK functions for that resource.

2. **Master State.** Holds a `Map<String, Model>` of all known items (keyed by unique ID), a detail cache for extended models (e.g., `UserPrivate`), and aggregated metadata (counts, stats).

3. **Derived Providers.** Filtered/computed views (e.g., `coachListProvider`, `organizerListProvider`, `userStatsProvider`) derive from the master using `ref.watch()`. They never make independent server calls.

4. **UI-layer Providers.** Filter state, search, and sort logic remain in the feature package (e.g., `cl_club_members`). These providers watch the master + local filter state and apply client-side filtering/sorting.

5. **Lazy Loading Safety.** Master providers are lazy (Riverpod default) — they only build when first watched. Role-restricted providers (e.g., `clUsersMasterProvider`) are only watched by admin/coach screens, so they never load for regular members. Regular members use `authStateProvider` for their own profile and public providers for coach info.

## Widget Mutation Pattern

Widgets call mutation methods on the master notifier instead of SDK directly:

```dart
// DO: call master notifier
await ref.read(userMasterProvider.notifier).approveUser(username);

// DON'T: call SDK directly from widget
final client = await ref.read(clientProvider.future);
await client.users.approveUser(username);
```

No manual `replaceLocally`, `removeLocally`, or `invalidate` calls — all watching providers rebuild automatically.

### Host pattern is the standard — the builder pattern is retired

Action/mutation widgets follow the **host pattern**: a feature-layer widget reads the master notifier and calls its mutation method directly (as above), owns its own loading/error state (a `_running` flag + an error toast), and — for list-row cards — resolves a typed `List<ActionItem>` it hands to `EntityCard.trailingActions` via a `builder` callback. See `AdminGroupActions`, `AdminUserActions`, `UserEventActions`, `UserOccurrenceActions`.

The older **builder pattern** — `ActionButtonBuilderStateBase` plus `*Builder` widgets in `cl_remote_store/lib/src/builders/` that you handed visual callbacks to — is **retired** (issue #639). Do **not** add new `*Builder` widgets; write a host widget instead. The card migration in #501 moved every card off builders because `EntityCard.trailingActions` needs typed `ActionItem` data, not an opaque `Widget`; keeping one pattern removes the duplicated action logic that resulted.

Trade-off: the host pattern places the mutation *invocation* in feature libraries rather than centralizing it in `cl_remote_store`. That is fine — the SDK Access Boundary is unchanged: feature widgets call the **master notifier's** mutation method, never the SDK client (which stays inside `cl_remote_store` / `cl_member_auth`).

## Mutation Response Rule

SDK mutation methods (including DELETE operations) return the updated entity whenever the server provides one. Master notifiers use the returned entity to update local state via `_replaceLocally(updated)` — never refetch or invalidate when the server already gives you the answer. `RemoteStore.delete()` returns `Map<String, dynamic>?`: parsed body for 200 responses, `null` for 204. Callers that don't need the response ignore it.

## Optimistic Updates

Status mutations update local state first, call the server, then reconcile. On failure, revert to pre-mutation state. CRUD mutations (create, update, delete) call the server first, then update local state with the server response.

## Auth Sync

When a mutation affects the logged-in user, the calling widget invalidates `authStateProvider`. The master notifier does not cross into the auth module.

## Shared Models

Pure data classes used across modules (e.g., `UserListFilter`, `UserStats`) live in `club_sdk_2`. Feature packages re-export them for backward compatibility.
