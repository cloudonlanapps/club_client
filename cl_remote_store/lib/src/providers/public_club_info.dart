import 'package:cl_remote_store/src/utils/public_read.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The club's public identity document (club_core#53): `clubInfo` as the
/// admin edits it (typed as `PublicClubInfo.identity`), and `siteMedia`
/// mapping each website slot to its media. One token-free fetch for both,
/// so the apps and the website read the same thing.
///
/// Readers that must never block — contact details, club content, site
/// media — read it through `valueOrNull` and fall back to a bundled
/// default, so a slow, failed or unconfigured server costs a stale value
/// rather than an empty page.
final AutoDisposeFutureProvider<PublicClubInfo> clPublicClubInfoProvider =
    FutureProvider.autoDispose<PublicClubInfo>((ref) {
      return readPublic(ref, (source) => source.getPublicClubInfo());
    });
