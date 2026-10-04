import 'package:cl_member_auth/cl_member_auth.dart' show AuthNotifier;
import 'package:club_sdk_2/club_sdk_2.dart';

import '../data/dummy_data.dart';
import 'demo_scenario.dart';

/// Overrides `authStateProvider` with the currently selected scenario.
///
/// `setUser` is also wired so calls from the onboarding flow (e.g.
/// `submitForReviewForSelf` returning the new `UserPrivate`) advance
/// the demo state visibly.
class DummyAuthNotifier extends AuthNotifier {
  @override
  Future<UserPrivate?> build() async {
    final scenario = ref.watch(demoScenarioProvider);
    return DummyData.userFor(scenario);
  }

  @override
  Future<void> logout() async {
    // No real session — flip back to the entry-point scenario so the
    // demo restarts cleanly.
    ref.read(demoScenarioProvider.notifier).state =
        OnboardingScenario.registeredFresh;
  }
}
