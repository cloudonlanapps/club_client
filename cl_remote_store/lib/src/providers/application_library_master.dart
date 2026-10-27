import 'package:cl_remote_store/src/providers/application_clauses.dart';
import 'package:cl_remote_store/src/providers/capabilities.dart';
import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/current_user.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/utils/uncertain_write.dart';
import 'package:cl_remote_store/src/utils/writes_during_load.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// Master provider for the club's library of application texts
/// (club_client#389, club_server#126): club-wide texts an admin pastes into
/// any template as written, beside the server's built-in clauses. Keyed by
/// id, oldest first.
///
/// An admin's alone. Empty, with no server call, while
/// [applicationsProvider] is not `true` or the signed-in user is not an
/// admin: the routes answer 403 to anyone else and 503 where the module is
/// off.
///
/// Each write folds the server's answer in (a delete removes the text) and
/// reloads [applicationClausesProvider], whose list carries the club's
/// texts. A write that may have landed reloads both instead
/// ([refetchIfWriteUncertain]).
final AsyncNotifierProvider<
  ClApplicationLibraryMasterNotifier,
  Map<int, ApplicationLibraryText>
>
clApplicationLibraryMasterProvider =
    AsyncNotifierProvider<
      ClApplicationLibraryMasterNotifier,
      Map<int, ApplicationLibraryText>
    >(ClApplicationLibraryMasterNotifier.new);

/// Notifier over the club's library texts and their writes.
class ClApplicationLibraryMasterNotifier
    extends AsyncNotifier<Map<int, ApplicationLibraryText>> {
  final _writes = WritesDuringLoad<int, ApplicationLibraryText>();

  @override
  Future<Map<int, ApplicationLibraryText>> build() => _writes.load(() async {
    ref.watch(clManualRefreshProvider);
    final enabled = ref.watch(applicationsProvider);
    final isAdmin = ref.watch(currentUserProvider)?.isAdmin ?? false;
    if (enabled != true || !isAdmin) return const {};
    final client = await ref.watch(secureClientProvider.future);
    final texts = await client.applications.listLibraryTexts();
    return {for (final t in texts) t.id: t};
  });

  /// Adds a library text. A shape the server refuses (a name not 1–100
  /// characters, an empty text, a heading on a kind that is not a rule) is
  /// 422 `VALIDATION_ERROR`, thrown as the SDK raised it.
  Future<ApplicationLibraryText> createLibraryText(
    ApplicationLibraryTextInput input,
  ) => writeLibraryText((source) => source.createLibraryText(input));

  /// Changes library text [id]: the fields [patch] gives replace the
  /// stored ones. Refused as [createLibraryText] is; an unknown [id] is 404
  /// `APPLICATION_LIBRARY_TEXT_NOT_FOUND`.
  Future<ApplicationLibraryText> updateLibraryText(
    int id,
    ApplicationLibraryTextPatch patch,
  ) => writeLibraryText((source) => source.updateLibraryText(id, patch));

  /// Removes library text [id] for good. No template changes: a template
  /// holds the texts pasted into it.
  Future<void> deleteLibraryText(int id) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      await client.applications.deleteLibraryText(id);
      final next = _writes.remove(state.valueOrNull, id);
      if (next != null) state = AsyncData(next);
      ref.invalidate(applicationClausesProvider);
    }, refetch: reload);
  }

  /// Reloads this list and the clauses list, after a write that may have
  /// landed.
  @protected
  void reload() {
    ref
      ..invalidateSelf()
      ..invalidate(applicationClausesProvider);
  }

  /// Replaces or adds [text] in the local map.
  void replaceLocally(ApplicationLibraryText text) {
    final next = _writes.put(state.valueOrNull, text.id, text);
    if (next != null) state = AsyncData(next);
  }

  /// Runs one server write, folds its answer into state and reloads the
  /// clauses list; a write that may have landed reloads instead
  /// ([refetchIfWriteUncertain]).
  @protected
  Future<ApplicationLibraryText> writeLibraryText(
    Future<ApplicationLibraryText> Function(ApplicationSource source) write,
  ) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final text = await write(client.applications);
      replaceLocally(text);
      ref.invalidate(applicationClausesProvider);
      return text;
    }, refetch: reload);
  }
}
