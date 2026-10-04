import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/current_user.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/utils/uncertain_write.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tag used for every user's identity-document links in the v2 media link
/// table. Server validation requires tags to match `^[A-Za-z0-9_-]{1,64}$`,
/// so the underscore form is mandatory (no hyphen).
const String kIdentityDocumentTag = 'identity_document';

/// Access roles applied to every identity-document `Media` upload. ID docs
/// are visible only to the owner and admins — coaches and the public do not
/// see them. The server's admin-review queries run as `admin`, which is
/// included here.
const List<String> kIdentityDocumentAccessRoles = ['self', 'admin'];

/// Master state for a single user's identity-document links, keyed by
/// `username`. State is the list of `MediaLink` records under
/// [kIdentityDocumentTag], sorted by `createdAtUtc` ascending (oldest first
/// — matches the order the server returns).
///
/// Self callers see their own docs; admins see any user's docs. Server-side
/// authorization (`self` or `admin`) gates access; the master simply
/// propagates the SDK call. Non-authenticated reads return `const []`.
final AsyncNotifierProviderFamily<
  ClIdentityDocsMasterNotifier,
  List<MediaLink>,
  String
>
clIdentityDocsMasterProvider =
    AsyncNotifierProvider.family<
      ClIdentityDocsMasterNotifier,
      List<MediaLink>,
      String
    >(ClIdentityDocsMasterNotifier.new);

/// Notifier that owns identity-document upload / discard for one username.
///
/// Mirrors the avatar pattern (`avatarMutationProvider`): upload first,
/// attach second, soft-delete only after detach. Unlike avatar, identity
/// documents are additive — a user may have up to
/// `kIdentityDocumentMaxCount` documents at once, and `upload` appends
/// rather than replacing.
class ClIdentityDocsMasterNotifier
    extends FamilyAsyncNotifier<List<MediaLink>, String> {
  String get username => arg;

  @override
  Future<List<MediaLink>> build(String arg) async {
    ref.watch(clManualRefreshProvider);
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return const [];
    final client = await ref.watch(secureClientProvider.future);
    return client.userMedia.listByTag(arg, kIdentityDocumentTag);
  }

  /// Upload [bytes] as a new identity-document `Media` and attach it under
  /// [kIdentityDocumentTag]. Returns the created link.
  Future<MediaLink> upload({
    required List<int> bytes,
    required String filename,
    required String contentType,
  }) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final media = await client.media.upload(
        fileBytes: bytes,
        filename: filename,
        contentType: contentType,
        accessRoles: kIdentityDocumentAccessRoles,
        // Identity documents are sensitive PII and must be encrypted at
        // rest (#754). The server holds the KEK and does AES-256-GCM; the
        // client only opts in. Requires the deployment to have
        // ENCRYPTION_KEY configured — otherwise the upload fails with
        // ENCRYPTION_NOT_CONFIGURED (handled by the onboarding upload UI).
        encrypt: true,
      );
      final link = await client.userMedia.attach(
        username,
        tag: kIdentityDocumentTag,
        mediaUuid: media.uuid,
      );
      final current = state.valueOrNull ?? const <MediaLink>[];
      state = AsyncData([...current, link]);
      return link;
    }, refetch: ref.invalidateSelf);
  }

  /// Detach the link for [mediaUuid] and soft-delete the underlying media.
  ///
  /// Detach happens first — the server returns `409 MEDIA_IN_USE` if soft
  /// delete sees a live link. Soft-delete failures are logged (best-effort
  /// cleanup) so the orphaned media row doesn't block the user-visible
  /// detach succeeding.
  Future<void> discard(String mediaUuid) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      await client.userMedia.detach(username, kIdentityDocumentTag, mediaUuid);
      try {
        await _softDeleteByUuid(client, mediaUuid);
      } on Object catch (e, st) {
        debugPrint(
          'clIdentityDocsMasterProvider.discard: softDelete failed for '
          '$mediaUuid: $e\n$st',
        );
      }
      final current = state.valueOrNull ?? const <MediaLink>[];
      state = AsyncData([
        for (final link in current)
          if (link.mediaUuid != mediaUuid) link,
      ]);
    }, refetch: ref.invalidateSelf);
  }

  /// Force a refetch of the link list.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build(arg));
  }

  Future<void> _softDeleteByUuid(SecureClient client, String mediaUuid) async {
    // The link table only carries the uuid. MediaSource.softDelete operates
    // on the numeric id, so resolve uuid → id via listMyFiles. Admin-side
    // discard cannot resolve another user's media this way and will simply
    // skip soft-delete (the detach already succeeded). Server caps `limit`
    // at 100; a doc buried deeper than that page silently remains an orphan
    // media row (best-effort cleanup).
    final myFiles = await client.media.listMyFiles(limit: 100);
    final found = myFiles.items.where((m) => m.uuid == mediaUuid).toList();
    if (found.isEmpty) return;
    await client.media.softDelete(found.first.id);
  }
}
