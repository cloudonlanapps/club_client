import 'package:cl_remote_store/src/providers/capabilities.dart';
import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/utils/bump_evaluations_version.dart';
import 'package:cl_remote_store/src/utils/fetch_all_pages.dart';
import 'package:cl_remote_store/src/utils/uncertain_write.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// Master provider for the caller's own evaluations, the coach's surface
/// (club_core#173).
///
/// Holds every evaluation the server lists for the caller — only those of
/// which they are the effective owner, so an admin's map is empty — all
/// pages loaded, keyed by id. Empty, with no server call, unless
/// [evaluationsProvider] is `true`. Lazy, so a member never loads it.
///
/// Each write replaces the evaluation locally with the staff view the
/// server returns, and bumps `evaluationsVersion` so the member-surface
/// providers refetch. A soft-deleted evaluation stays in the map with
/// `deletedAtUtc` set until the next load, so it can be restored; views
/// filter on `deletedAtUtc == null`.
final AsyncNotifierProvider<
  ClEvaluationsMasterNotifier,
  Map<int, EvaluationStaffView>
>
clEvaluationsMasterProvider =
    AsyncNotifierProvider<
      ClEvaluationsMasterNotifier,
      Map<int, EvaluationStaffView>
    >(ClEvaluationsMasterNotifier.new);

/// Notifier over the caller's evaluations and every write to them.
class ClEvaluationsMasterNotifier
    extends AsyncNotifier<Map<int, EvaluationStaffView>> {
  @override
  Future<Map<int, EvaluationStaffView>> build() async {
    ref.watch(clManualRefreshProvider);
    if (ref.watch(evaluationsProvider) != true) return const {};
    final client = await ref.watch(secureClientProvider.future);
    final views = await fetchAllPages(client.evaluations.listEvaluations);
    return {for (final v in views) v.id: v};
  }

  /// Creates a draft with no answers for member [createdFor] from template
  /// [templateId]: about event [eventId], or general when null, over an
  /// optional period (both bounds or neither). Coach only; an event
  /// evaluation needs the caller on its coach list and the member's
  /// attendance (422 `NOT_ELIGIBLE`).
  Future<EvaluationStaffView> createEvaluation({
    required int templateId,
    required String createdFor,
    int? eventId,
    DateTime? periodStartUtc,
    DateTime? periodEndUtc,
  }) => writeEvaluation(
    (source) => source.createEvaluation(
      templateId: templateId,
      createdFor: createdFor,
      eventId: eventId,
      periodStartUtc: periodStartUtc,
      periodEndUtc: periodEndUtc,
    ),
  );

  /// Changes draft [id]'s event, its period, or both. Each getter follows
  /// the SDK's ValueGetter pattern: omitted leaves that field as it is, a
  /// getter returning null clears it — `eventId: () => null` makes the draft
  /// general. A period is sent whole: both bounds, or both cleared.
  ///
  /// The server checks eligibility again for the resulting event and
  /// period (422 `NOT_ELIGIBLE`, 404 `EVENT_NOT_FOUND`) and refuses a second
  /// live review of the same key (422 `DUPLICATE_EVALUATION`) or a period
  /// ending after today (422 `PERIOD_IN_FUTURE`).
  Future<EvaluationStaffView> updateEvaluation(
    int id, {
    int? Function()? eventId,
    DateTime? Function()? periodStartUtc,
    DateTime? Function()? periodEndUtc,
  }) => writeEvaluation(
    (source) => source.updateEvaluation(
      id,
      eventId: eventId,
      periodStartUtc: periodStartUtc,
      periodEndUtc: periodEndUtc,
    ),
  );

  /// Writes [answer] to item [itemId] of draft [id], replacing any earlier
  /// one (422 `INVALID_ANSWER` when it does not fit the item).
  Future<EvaluationStaffView> putAnswer(
    int id,
    int itemId,
    EvaluationAnswerInput answer,
  ) => writeEvaluation((source) => source.putAnswer(id, itemId, answer));

  /// Clears the answer to item [itemId] of draft [id], detaching its
  /// evidence.
  Future<EvaluationStaffView> clearAnswer(int id, int itemId) =>
      writeEvaluation((source) => source.clearAnswer(id, itemId));

  /// draft → saved.
  ///
  /// An incomplete draft is refused with the SDK's [ServerException] 422
  /// `INCOMPLETE`, rethrown unchanged and the state left as it was; its
  /// `details['details']['itemIds']` names the items, which
  /// `evaluationIncompleteItemIds(error)` reads.
  Future<EvaluationStaffView> saveEvaluation(int id) =>
      writeEvaluation((source) => source.saveEvaluation(id));

  /// saved → published: the server stores the member copy and notifies the
  /// member.
  Future<EvaluationStaffView> publishEvaluation(int id) =>
      writeEvaluation((source) => source.publishEvaluation(id));

  /// published → saved; the member is notified.
  Future<EvaluationStaffView> unpublishEvaluation(int id) =>
      writeEvaluation((source) => source.unpublishEvaluation(id));

  /// saved → draft.
  Future<EvaluationStaffView> revertEvaluation(int id) =>
      writeEvaluation((source) => source.revertEvaluation(id));

  /// Soft-deletes draft [id]; the deleted row stays in the map.
  Future<EvaluationStaffView> deleteEvaluation(int id) =>
      writeEvaluation((source) => source.deleteEvaluation(id));

  /// Restores soft-deleted evaluation [id].
  Future<EvaluationStaffView> restoreEvaluation(int id) =>
      writeEvaluation((source) => source.restoreEvaluation(id));

  /// Hands unpublished evaluation [id] to coach [owner]. The server answers
  /// with no content and the evaluation leaves the caller's view, so it is
  /// removed locally.
  Future<void> transferEvaluation(int id, {required String owner}) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      await client.evaluations.transferEvaluation(id, owner: owner);
      removeLocally(id);
      bumpEvaluationsVersion(ref);
    }, refetch: refetchAfterUncertainWrite);
  }

  /// Uploads a file — an image, a video or a PDF — as evidence on item
  /// [itemId] of draft [id], in one call, and replaces the evaluation
  /// locally with the server's answer.
  ///
  /// The server stores the file as the member's (the evaluation's
  /// `createdFor` is its uploader), downloadable by the member and staff
  /// only — never public — and links it under the item (club_server#535,
  /// R56d). 422 `INVALID_EVIDENCE` when the item takes no evidence or the
  /// file is of another kind; 413 `FILE_TOO_LARGE` over the server's limit.
  Future<EvaluationStaffView> uploadEvidence(
    int id,
    int itemId, {
    required List<int> bytes,
    required String filename,
    String? contentType,
  }) => writeEvaluation(
    (source) => source.uploadEvidence(
      id,
      itemId,
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    ),
  );

  /// Detaches evidence [mediaUuid] from item [itemId] of draft [id], then
  /// refetches the evaluation.
  Future<EvaluationStaffView> detachEvidence(
    int id,
    int itemId,
    String mediaUuid,
  ) => writeEvidence(
    id,
    (client) => client.evaluationMedia.detach(
      id,
      EvaluationMediaTags.evidence(itemId),
      mediaUuid,
    ),
  );

  /// The member copy of evaluation [id] as it would be published, as PDF
  /// bytes: generated on request, never stored. A read; state is unchanged.
  Future<List<int>> previewPdf(int id) async {
    final client = await ref.read(secureClientProvider.future);
    return client.evaluations.previewMemberCopy(id);
  }

  /// Replaces or adds [view] in the local map.
  void replaceLocally(EvaluationStaffView view) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData({...current, view.id: view});
  }

  /// Removes evaluation [id] from the local map.
  void removeLocally(int id) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(Map.of(current)..remove(id));
  }

  /// After an evaluation write that may have landed: reload this map and
  /// every evaluation view.
  void refetchAfterUncertainWrite() {
    ref.invalidateSelf();
    bumpEvaluationsVersion(ref);
  }

  /// Runs one server write and folds its answer into state; a write that
  /// may have landed reloads instead ([refetchIfWriteUncertain]).
  @protected
  Future<EvaluationStaffView> writeEvaluation(
    Future<EvaluationStaffView> Function(EvaluationSource source) write,
  ) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final view = await write(client.evaluations);
      replaceLocally(view);
      bumpEvaluationsVersion(ref);
      return view;
    }, refetch: refetchAfterUncertainWrite);
  }

  /// Runs one evidence write on evaluation [id], then refetches it into
  /// state; a write that may have landed reloads instead.
  @protected
  Future<EvaluationStaffView> writeEvidence(
    int id,
    Future<Object?> Function(SecureClient client) write,
  ) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      await write(client);
      final view = await client.evaluations.getEvaluation(id);
      replaceLocally(view);
      bumpEvaluationsVersion(ref);
      return view;
    }, refetch: refetchAfterUncertainWrite);
  }
}
