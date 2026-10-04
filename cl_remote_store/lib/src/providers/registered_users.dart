import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/current_user.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/utils/fetch_all_pages.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Users who signed up but have not submitted for review (`registered`),
/// for admins and coaches (#91).
///
/// `clUsersMasterProvider` leaves them out, and so does the server's default
/// user list, so the Members screen fetches them only when asked for, with
/// `status=registered`. Anyone else gets an empty list without a request.
final AutoDisposeFutureProvider<List<UserInfo>> clRegisteredUsersProvider =
    FutureProvider.autoDispose<List<UserInfo>>((ref) async {
      ref.watch(clManualRefreshProvider);
      final viewer = ref.watch(currentUserProvider);
      if (viewer == null || !viewer.isCoachOrAdmin) return const [];
      final client = await ref.watch(secureClientProvider.future);
      return fetchAllPages(
        ({required offset, required limit}) => client.users.getUsers(
          offset: offset,
          limit: limit,
          status: UserStatus.registered,
        ),
      );
    });
