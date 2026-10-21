import 'package:cl_remote_store/src/providers/resource_version.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bumps `attendanceVersion` on [clResourceVersionProvider] after an
/// attendance write, so the member's attendance list and occurrences
/// refetch (club_client#232).
void bumpAttendanceVersion(Ref ref) {
  final current = ref.read(clResourceVersionProvider);
  ref.read(clResourceVersionProvider.notifier).state = current.copyWith(
    attendanceVersion: current.attendanceVersion + 1,
  );
}
