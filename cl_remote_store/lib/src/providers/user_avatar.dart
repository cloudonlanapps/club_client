import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/media_download_url.dart';
import 'package:cl_remote_store/src/providers/mutation_guard.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tag used for every user's profile avatar in the v2 media link table.
///
/// Server validation requires tags to match `^[A-Za-z0-9_-]{1,64}$`, so
/// the underscore form is mandatory.
const String kUserAvatarTag = 'user_avatar';

/// Most-recent avatar download URL for `username`, or `null` if the user
/// has no avatar attached.
///
/// Resolves by listing `user/avatar`-tagged links via `UserMediaSource`,
/// picking the most recently created entry, and routing the uuid through
/// `mediaDownloadUrlProvider`.
final FutureProviderFamily<String?, String> avatarImageProvider =
    FutureProvider.family<String?, String>((ref, username) async {
      final client = await ref.watch(secureClientProvider.future);
      final links = await client.userMedia.listByTag(username, kUserAvatarTag);
      if (links.isEmpty) return null;
      final sorted = [...links]
        ..sort((a, b) => b.createdAtUtc.compareTo(a.createdAtUtc));
      final mostRecent = sorted.first;
      return ref.read(
        mediaDownloadUrlProvider(
          (uuid: mostRecent.mediaUuid, variant: 'original'),
        ),
      );
    });

/// Whether the user's current avatar (most-recent `user_avatar`-tagged
/// media) is marked publicly visible, i.e. its `accessRoles` contains
/// `'public'`. Returns `false` when the user has no avatar, or when the
/// most-recent linked media isn't present in the caller's `listMyFiles`
/// page (admin viewing another user's avatar — caller should not rely on
/// the result in that case).
///
/// Used to seed the "Allow others to see my photo" checkbox in the
/// upload preview dialog so it remembers the user's previous choice.
final FutureProviderFamily<bool, String> avatarVisibilityProvider =
    FutureProvider.family<bool, String>((ref, username) async {
      final client = await ref.watch(secureClientProvider.future);
      final links = await client.userMedia.listByTag(username, kUserAvatarTag);
      if (links.isEmpty) return false;
      final sorted = [...links]
        ..sort((a, b) => b.createdAtUtc.compareTo(a.createdAtUtc));
      final mostRecentUuid = sorted.first.mediaUuid;
      // Server caps `limit` at 100. The just-uploaded avatar is the user's
      // most-recent media, so the first page is sufficient here.
      final myFiles = await client.media.listMyFiles(limit: 100);
      final match = myFiles.items
          .where((m) => m.uuid == mostRecentUuid)
          .toList();
      if (match.isEmpty) return false;
      return match.first.accessRoles.contains('public');
    });

/// Mutation surface for a single user's avatar.
///
/// Widgets call [AvatarMutationNotifier.upload] or
/// [AvatarMutationNotifier.clear]; reads observe [avatarImageProvider].
/// The notifier handles the upload → attach → soft-delete-previous flow
/// in an order that keeps the user with a renderable avatar across
/// upload-or-attach failures.
final AvatarMutationProvider avatarMutationProvider =
    AsyncNotifierProvider.family<AvatarMutationNotifier, void, String>(
      AvatarMutationNotifier.new,
    );

/// Convenience alias for the family type used by [avatarMutationProvider].
typedef AvatarMutationProvider =
    AsyncNotifierProviderFamily<AvatarMutationNotifier, void, String>;

/// Notifier that owns avatar upload / clear for a single user.
class AvatarMutationNotifier extends FamilyAsyncNotifier<void, String>
    with MediaMutationGuard<String> {
  @override
  Future<void> build(String username) async {
    // Idle. Mutation methods drive state transitions.
  }

  /// Upload [bytes] as the user's avatar and replace any prior avatar
  /// under [kUserAvatarTag].
  ///
  /// [allowOthersToSee] selects the new media's access roles:
  ///   - `true`  → `['public']`
  ///   - `false` → `['self', 'admin', 'coach']`
  ///
  /// On a failure during upload or attach, prior media is preserved.
  /// Prior media is only soft-deleted after the new link has been
  /// successfully attached.
  Future<void> upload({
    required List<int> bytes,
    required String filename,
    required String contentType,
    required bool allowOthersToSee,
  }) async {
    final username = arg;
    await runGuarded('Avatar.upload', () async {
      final client = await ref.read(secureClientProvider.future);
      final priorLinks = await client.userMedia.listByTag(
        username,
        kUserAvatarTag,
      );
      final media = await client.media.upload(
        fileBytes: bytes,
        filename: filename,
        contentType: contentType,
        accessRoles: allowOthersToSee
            ? const ['public']
            : const ['self', 'admin', 'coach'],
      );
      await client.userMedia.attach(
        username,
        tag: kUserAvatarTag,
        mediaUuid: media.uuid,
      );
      // Replace each prior avatar: detach the link, then soft-delete the
      // media. The order matters — the server returns 409 MEDIA_IN_USE
      // if soft-delete sees a live link. Both calls are expected to
      // succeed; failures are logged (not swallowed) so any real fault
      // surfaces in the console without aborting the rest of the loop.
      for (final prior in priorLinks) {
        try {
          await client.userMedia.detach(
            username,
            kUserAvatarTag,
            prior.mediaUuid,
          );
          await _softDeleteByUuid(client, prior.mediaUuid);
        } on Object catch (e, st) {
          debugPrint(
            'avatarMutationProvider: cleanup failed for prior media '
            '${prior.mediaUuid}: $e\n$st',
          );
        }
      }
      ref
        ..invalidate(avatarImageProvider(username))
        ..invalidate(avatarVisibilityProvider(username));
    }, refetch: () => refetchAvatar(username));
  }

  /// Detach and soft-delete every avatar media for the user.
  Future<void> clear() async {
    final username = arg;
    await runGuarded('Avatar.clear', () async {
      final client = await ref.read(secureClientProvider.future);
      final links = await client.userMedia.listByTag(
        username,
        kUserAvatarTag,
      );
      await client.userMedia.detachTag(username, kUserAvatarTag);
      for (final link in links) {
        try {
          await _softDeleteByUuid(client, link.mediaUuid);
        } on Object catch (e, st) {
          debugPrint(
            'avatarMutationProvider.clear: softDelete failed for '
            '${link.mediaUuid}: $e\n$st',
          );
        }
      }
      ref
        ..invalidate(avatarImageProvider(username))
        ..invalidate(avatarVisibilityProvider(username));
    }, refetch: () => refetchAvatar(username));
  }

  /// Reload the avatar and its visibility for [username].
  void refetchAvatar(String username) {
    ref
      ..invalidate(avatarImageProvider(username))
      ..invalidate(avatarVisibilityProvider(username));
  }

  Future<void> _softDeleteByUuid(SecureClient client, String mediaUuid) async {
    // The link table only carries the uuid. MediaSource.softDelete operates
    // on the numeric id, so a fetch-by-uuid would be needed — but that API
    // doesn't exist. List my files and resolve uuid → id. Server caps
    // `limit` at 100; a prior avatar buried deeper than that will silently
    // remain an orphan media row (best-effort cleanup, logged by caller).
    final myFiles = await client.media.listMyFiles(limit: 100);
    final found = myFiles.items.where((m) => m.uuid == mediaUuid).toList();
    if (found.isEmpty) return;
    await client.media.softDelete(found.first.id);
  }
}
