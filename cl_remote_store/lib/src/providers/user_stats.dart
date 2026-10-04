import 'package:cl_remote_store/src/providers/users_master.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Aggregated user stats derived from [clUsersMasterProvider].
///
/// Provides computed counts that automatically update when users are created,
/// deleted, or change status through the master notifier.
final AutoDisposeFutureProvider<ClUserStatsData> clUserStatsProvider =
    FutureProvider.autoDispose<ClUserStatsData>((ref) async {
      final users = await ref.watch(clUsersMasterProvider.future);
      return ClUserStatsData.fromMap(users);
    });

/// Simple stats container computed from the user map.
class ClUserStatsData {
  const ClUserStatsData({
    this.total = 0,
    this.activeCount = 0,
    this.pendingCount = 0,
    this.blockedCount = 0,
    this.leftCount = 0,
    this.registeredCount = 0,
  });

  factory ClUserStatsData.fromMap(Map<String, UserInfo> users) {
    return ClUserStatsData(
      total: users.length,
      activeCount: users.values
          .where((u) => u.status == UserStatus.active)
          .length,
      pendingCount: users.values
          .where((u) => u.status == UserStatus.pending)
          .length,
      blockedCount: users.values
          .where((u) => u.status == UserStatus.blocked)
          .length,
      leftCount: users.values.where((u) => u.status == UserStatus.left).length,
      registeredCount: users.values
          .where((u) => u.status == UserStatus.registered)
          .length,
    );
  }

  final int total;
  final int activeCount;
  final int pendingCount;
  final int blockedCount;
  final int leftCount;
  final int registeredCount;

  /// Count of users matching the given [status].
  int countByStatus(UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return activeCount;
      case UserStatus.pending:
        return pendingCount;
      case UserStatus.blocked:
        return blockedCount;
      case UserStatus.left:
        return leftCount;
      case UserStatus.registered:
        return registeredCount;
    }
  }
}
