import 'package:cl_remote_store/src/providers/resource_version.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bumps `evaluationsVersion` on [clResourceVersionProvider] after an
/// evaluation or template write, so the member's published evaluations and
/// their media refetch (club_core#173).
void bumpEvaluationsVersion(Ref ref) {
  final current = ref.read(clResourceVersionProvider);
  ref.read(clResourceVersionProvider.notifier).state = current.copyWith(
    evaluationsVersion: current.evaluationsVersion + 1,
  );
}
