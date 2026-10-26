import 'package:cl_remote_store/src/providers/capabilities.dart';
import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/current_user.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/utils/uncertain_write.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Master provider for the club's profile options (club_client#320): the
/// positions and languages a member picks their preferred one from, the
/// `profile_options` preference.
///
/// Any signed-in member may read it, approved or not. While the extended
/// profile is off or unknown ([extendedProfileProvider]), or no one is
/// signed in, it holds empty options without a server call: nothing shows
/// them then.
final AsyncNotifierProvider<ProfileOptionsNotifier, ProfileOptions>
profileOptionsProvider =
    AsyncNotifierProvider<ProfileOptionsNotifier, ProfileOptions>(
      ProfileOptionsNotifier.new,
    );

/// Notifier of [profileOptionsProvider]: reads the options and saves an
/// admin's edit of them.
class ProfileOptionsNotifier extends AsyncNotifier<ProfileOptions> {
  @override
  Future<ProfileOptions> build() async {
    ref.watch(clManualRefreshProvider);
    final enabled = ref.watch(extendedProfileProvider);
    final currentUser = ref.watch(currentUserProvider);
    if (enabled != true || currentUser == null) return const ProfileOptions();
    final client = await ref.watch(secureClientProvider.future);
    return client.users.getProfileOptions();
  }

  /// Replace the club's options with [options] (admin) and hold what the
  /// server stored. A refusal (`ServerException`) is rethrown and the
  /// stored options kept; a failure that may have landed re-reads them
  /// ([refetchIfWriteUncertain]).
  Future<ProfileOptions> save(ProfileOptions options) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final stored = await client.users.setProfileOptions(options);
      state = AsyncData(stored);
      return stored;
    }, refetch: ref.invalidateSelf);
  }
}
