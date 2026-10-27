import 'dart:typed_data';

import 'package:cl_remote_store/src/providers/capabilities.dart';
import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/current_user.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/utils/fetch_all_pages.dart';
import 'package:cl_remote_store/src/utils/uncertain_write.dart';
import 'package:cl_remote_store/src/utils/writes_during_load.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// Master provider for the application templates (club_client#321), all
/// pages loaded, keyed by id.
///
/// An admin holds every template, in every state; anyone else the
/// published ones, and only once they have uploaded an identity document
/// (the server lists none before that). Empty, with no server call, while
/// [applicationsProvider] is not `true` or no one is signed in: the routes
/// answer 503 where the module is off.
///
/// Each write replaces the template locally with the one the server
/// returns; a delete removes it. A write that may have landed reloads the
/// list instead ([refetchIfWriteUncertain]). The PDF downloads are reads
/// and change nothing here.
final AsyncNotifierProvider<
  ClApplicationsMasterNotifier,
  Map<int, ApplicationTemplate>
>
clApplicationsMasterProvider =
    AsyncNotifierProvider<
      ClApplicationsMasterNotifier,
      Map<int, ApplicationTemplate>
    >(ClApplicationsMasterNotifier.new);

/// Notifier over the application templates, their writes, their moves and
/// the forms' PDFs.
class ClApplicationsMasterNotifier
    extends AsyncNotifier<Map<int, ApplicationTemplate>> {
  final _writes = WritesDuringLoad<int, ApplicationTemplate>();

  @override
  Future<Map<int, ApplicationTemplate>> build() => _writes.load(() async {
    ref.watch(clManualRefreshProvider);
    final enabled = ref.watch(applicationsProvider);
    final currentUser = ref.watch(currentUserProvider);
    if (enabled != true || currentUser == null) return const {};
    final client = await ref.watch(secureClientProvider.future);
    final templates = await fetchAllPages(
      client.applications.listApplications,
    );
    return {for (final t in templates) t.id: t};
  });

  /// Creates a draft from [content]; nothing is checked for completeness
  /// until [saveApplication]. Admin only.
  Future<ApplicationTemplate> createApplication(ApplicationContent content) =>
      writeApplication((source) => source.createApplication(content));

  /// Changes draft [id]: each field [patch] gives replaces the stored one.
  /// A saved or published template is 422 `INVALID_STATE`. Admin only.
  Future<ApplicationTemplate> updateApplication(
    int id,
    ApplicationPatch patch,
  ) => writeApplication((source) => source.updateApplication(id, patch));

  /// A new draft copied from template [id], in any state. Admin only.
  Future<ApplicationTemplate> duplicateApplication(int id) =>
      writeApplication((source) => source.duplicateApplication(id));

  /// Draft → saved: refused when incomplete
  /// (`ApplicationIncompleteException`), when a text names an unknown
  /// clause or fact (`APPLICATION_INVALID_REFERENCE`) or when the form does
  /// not fit (`ApplicationDoesNotFitException`). Admin only.
  Future<ApplicationTemplate> saveApplication(int id) =>
      writeApplication((source) => source.saveApplication(id));

  /// Saved → published: members see it. Admin only.
  Future<ApplicationTemplate> publishApplication(int id) =>
      writeApplication((source) => source.publishApplication(id));

  /// Published → saved: members no longer see it. Admin only.
  Future<ApplicationTemplate> unpublishApplication(int id) =>
      writeApplication((source) => source.unpublishApplication(id));

  /// Saved → draft: editable again, its layout dropped. Admin only.
  Future<ApplicationTemplate> revertApplication(int id) =>
      writeApplication((source) => source.revertApplication(id));

  /// Soft-deletes draft or saved template [id] and removes it here. A
  /// published one is 422 `INVALID_STATE`. Admin only.
  Future<void> deleteApplication(int id) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      await client.applications.deleteApplication(id);
      final next = _writes.remove(state.valueOrNull, id);
      if (next != null) state = AsyncData(next);
    }, refetch: ref.invalidateSelf);
  }

  /// Template [id], in any state, drawn for the server's demo member and
  /// watermarked "PREVIEW". Admin only.
  Future<Uint8List> downloadPreview(int id) =>
      readPdf((source) => source.downloadPreview(id));

  /// The signed-in member's own form of published template [id]. A member
  /// no age category matches is 422 `APPLICATION_NOT_ELIGIBLE`; [category]
  /// is the index of the age category to tick, needed when the member fits
  /// several (`ApplicationCategoryRequiredException`).
  Future<Uint8List> downloadOwnForm(int id, {int? category}) =>
      readPdf((source) => source.downloadOwnForm(id, category: category));

  /// [username]'s form of published template [id]. Admin only. [category]
  /// is chosen as for [downloadOwnForm].
  Future<Uint8List> downloadMemberForm(
    int id,
    String username, {
    int? category,
  }) => readPdf(
    (source) => source.downloadMemberForm(id, username, category: category),
  );

  /// Replaces or adds [template] in the local map.
  void replaceLocally(ApplicationTemplate template) {
    final next = _writes.put(state.valueOrNull, template.id, template);
    if (next != null) state = AsyncData(next);
  }

  /// Runs one server write and folds its answer into state; a write that
  /// may have landed reloads instead ([refetchIfWriteUncertain]).
  @protected
  Future<ApplicationTemplate> writeApplication(
    Future<ApplicationTemplate> Function(ApplicationSource source) write,
  ) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final template = await write(client.applications);
      replaceLocally(template);
      return template;
    }, refetch: ref.invalidateSelf);
  }

  /// Runs one PDF read and gives its bytes; a refusal is thrown as the SDK
  /// raised it.
  @protected
  Future<Uint8List> readPdf(
    Future<List<int>> Function(ApplicationSource source) read,
  ) async {
    final client = await ref.read(secureClientProvider.future);
    return Uint8List.fromList(await read(client.applications));
  }
}
