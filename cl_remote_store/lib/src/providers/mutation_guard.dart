import 'package:cl_remote_store/src/utils/uncertain_write.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Logs and rethrows when a mutation's [state] resolved to an error.
///
/// The media mutation notifiers assign `state = await AsyncValue.guard(...)`,
/// which *captures* a thrown error into [state] rather than propagating it.
/// The upload affordances wrap the mutation call in `try/catch` to show a
/// toast, but that catch never fired because guard swallowed the throw — so
/// upload failures were completely silent (issue #709: "fails silently, no log
/// no toast"). Call this immediately after assigning [state] so a failure is
/// both logged and rethrown for the widget to surface.
void throwIfMutationFailed(AsyncValue<void> state, String label) {
  if (state case AsyncError(:final error, :final stackTrace)) {
    debugPrint('$label failed: $error\n$stackTrace');
    Error.throwWithStackTrace(error, stackTrace);
  }
}

/// Shared mutation runner for the media notifiers (avatar, group, venue,
/// event). Sets the loading state, runs `body` under `AsyncValue.guard` so the
/// notifier's `state` reflects success/failure, then — crucially — logs and
/// **rethrows** any failure (see [throwIfMutationFailed]) so the calling
/// affordance's `try/catch` surfaces a toast instead of failing silently.
///
/// `refetch` reloads what `body` changes when it fails in a way that may
/// have reached the server (club_core#138): an upload or attach that timed
/// out may still have landed.
mixin MediaMutationGuard<ArgT> on FamilyAsyncNotifier<void, ArgT> {
  Future<void> runGuarded(
    String label,
    Future<void> Function() body, {
    required void Function() refetch,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => refetchIfWriteUncertain(body, refetch: refetch),
    );
    throwIfMutationFailed(state, label);
  }
}
