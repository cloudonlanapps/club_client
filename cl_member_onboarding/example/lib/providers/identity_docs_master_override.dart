import 'package:cl_remote_store/cl_remote_store.dart'
    show ClIdentityDocsMasterNotifier, kIdentityDocumentTag;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stub of `clIdentityDocsMasterProvider`.
///
/// Starts empty. `upload` synthesizes a `MediaLink` so the slot composer
/// surfaces it as a submitted document; `discard` removes from local state.
/// The real SDK is never called.
class DummyIdentityDocsMasterNotifier extends ClIdentityDocsMasterNotifier {
  int _nextId = 1;

  @override
  Future<List<MediaLink>> build(String arg) async => const [];

  @override
  Future<MediaLink> upload({
    required List<int> bytes,
    required String filename,
    required String contentType,
  }) async {
    final now = DateTime.now().toUtc();
    final id = 'demo-doc-${_nextId++}';
    final link = MediaLink(
      tag: kIdentityDocumentTag,
      media: MediaRef(uuid: id, mimeType: contentType, filename: id),
      createdAtUtc: now,
      updatedAtUtc: now,
    );
    final current = state.valueOrNull ?? const <MediaLink>[];
    state = AsyncData([...current, link]);
    return link;
  }

  @override
  Future<void> discard(String mediaUuid) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData([
      for (final link in current)
        if (link.mediaUuid != mediaUuid) link,
    ]);
  }
}
