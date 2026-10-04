import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Returns true if the currently-authenticated user may view the
/// my-groups screen for `username`.
///
/// Allowed when any of:
/// - the user is the same person (`user.username == username`)
/// - the user is admin or coach
final AutoDisposeFutureProviderFamily<bool, String> myGroupsAccessProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, username) async {
      final user = ref.watch(authStateProvider).valueOrNull;
      if (user == null) return false;
      if (user.username == username) return true;
      if (user.isCoachOrAdmin) return true;
      return false;
    });
