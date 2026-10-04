import 'package:cl_remote_store/src/providers/public_club_info.dart';
import 'package:cl_remote_store/src/utils/club_content_from_server.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The club's history and values — the About page's story — from the
/// server's public club info when it has them (club_core#53).
///
/// The family argument is the bundled copy, which the caller passes in
/// because only it can reach its localisations. Resolves synchronously and
/// never blocks, so the story renders whether or not the server answers;
/// see [clubContentFromServer] for how each part falls back.
final AutoDisposeProviderFamily<ClubInfo, ClubInfo>
clPublicClubContentProvider = Provider.autoDispose.family<ClubInfo, ClubInfo>(
  (ref, fallback) {
    final clubInfo = ref.watch(clPublicClubInfoProvider).valueOrNull?.clubInfo;
    if (clubInfo == null) return fallback;
    return clubContentFromServer(clubInfo, fallback: fallback);
  },
);
