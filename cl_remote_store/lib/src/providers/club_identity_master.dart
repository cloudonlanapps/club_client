import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/current_user.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/providers/public_club_info.dart';
import 'package:cl_remote_store/src/utils/uncertain_write.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Master provider for the club's identity (club_core#20): the `club_info`
/// preference as a typed [ClubIdentity] — name, short name, inquiry email
/// and the public contact block.
///
/// Read from, and written to, the super-admin `club_info` preference. The
/// read keeps the keys the model does not name in [ClubIdentity.extra], so a
/// [ClClubIdentityMasterNotifier.save] built from it carries them through.
///
/// Super-admin only, like the preference endpoint: anyone else gets an
/// empty identity without a server call.
final AsyncNotifierProvider<ClClubIdentityMasterNotifier, ClubIdentity>
clClubIdentityMasterProvider =
    AsyncNotifierProvider<ClClubIdentityMasterNotifier, ClubIdentity>(
      ClClubIdentityMasterNotifier.new,
    );

class ClClubIdentityMasterNotifier extends AsyncNotifier<ClubIdentity> {
  @override
  Future<ClubIdentity> build() async {
    ref.watch(clManualRefreshProvider);
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null || !currentUser.isSuperAdmin) {
      return const ClubIdentity();
    }
    final client = await ref.watch(secureClientProvider.future);
    return client.admin.getClubIdentity();
  }

  /// Write [identity] as the whole `club_info` document and hold what the
  /// server stored. A refusal (`ServerException`) is rethrown and the saved
  /// state kept; a failure that may have landed also re-reads the identity
  /// ([refetchIfWriteUncertain], club_core#138).
  ///
  /// Either way the public club info is re-read, so what reads it — the
  /// contact details (`contactInfoProvider`), the website's content — shows
  /// the edit without a restart (club_core#53).
  Future<ClubIdentity> save(ClubIdentity identity) {
    return refetchIfWriteUncertain(
      () async {
        final client = await ref.read(secureClientProvider.future);
        final stored = await client.admin.setClubIdentity(identity);
        state = AsyncData(stored);
        ref.invalidate(clPublicClubInfoProvider);
        return stored;
      },
      refetch: () {
        ref
          ..invalidateSelf()
          ..invalidate(clPublicClubInfoProvider);
      },
    );
  }
}
