import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Read-only public [UserInfo] for a username, via `getUserInfo`
/// (`GET /users/by_id/{username}`) — accessible to **any** active user.
///
/// Unlike `clUserPrivateProvider` (admin/coach/self only) and the admin
/// users master, this is reachable by ordinary members, so it can resolve a
/// coach's `displayName`, `publicId`, and `isPublicProfile` for linking into
/// the public profile view.
final AutoDisposeFutureProviderFamily<UserInfo, String> clUserInfoProvider =
    FutureProvider.autoDispose.family<UserInfo, String>((ref, username) async {
      ref.watch(clManualRefreshProvider);
      final client = await ref.read(secureClientProvider.future);
      return client.users.getUserInfo(username);
    });
