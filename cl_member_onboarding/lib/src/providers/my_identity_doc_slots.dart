import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_lib/ui_lib.dart';

/// Identity-document slots for the logged-in user, ready to hand to
/// `IdentityDocumentsUploader.initialItems`.
///
/// Sources from [clIdentityDocsMasterProvider] keyed by the current
/// username and maps each `MediaLink` to an [IdentityDocumentSlot]. Returns
/// an empty list when no user is logged in. The slot's `id` is the
/// underlying `mediaUuid`, which is also what the submit body passes back
/// to `discard` for deletion.
final AutoDisposeProvider<AsyncValue<List<IdentityDocumentSlot>>>
clMyIdentityDocSlotsProvider =
    Provider.autoDispose<AsyncValue<List<IdentityDocumentSlot>>>((ref) {
      final currentUser = ref.watch(authStateProvider).valueOrNull;
      if (currentUser == null) {
        return const AsyncData<List<IdentityDocumentSlot>>([]);
      }

      final linksAsync = ref.watch(
        clIdentityDocsMasterProvider(currentUser.username),
      );

      return linksAsync.whenData((links) {
        return [
          for (final link in links)
            IdentityDocumentSlot(
              id: link.mediaUuid,
              uri: ref.read(
                mediaDownloadUrlProvider(
                  (uuid: link.mediaUuid, variant: 'original'),
                ),
              ),
              mimeType: link.media.mimeType,
              // The server's stored name, so a document that fails to load
              // is still identifiable (#90).
              fileName: link.media.filename,
              // Link-level metadata does not carry the file size. The submit
              // body never re-validates server-stored slots against the byte
              // cap (only freshly picked files are validated), so 0 here is
              // harmless.
              sizeBytes: 0,
            ),
        ];
      });
    });
