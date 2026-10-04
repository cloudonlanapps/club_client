import 'package:cl_remote_store/src/providers/resource_version.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bumps `creditsVersion` on [clResourceVersionProvider] after a change that
/// moves credit, so every credit provider still watched refetches.
void bumpCreditsVersion(Ref ref) {
  final current = ref.read(clResourceVersionProvider);
  ref.read(clResourceVersionProvider.notifier).state = current.copyWith(
    creditsVersion: current.creditsVersion + 1,
  );
}
