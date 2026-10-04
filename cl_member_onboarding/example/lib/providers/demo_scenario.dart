import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dummy_data.dart';

/// The currently selected onboarding scenario.
///
/// The scenario dropdown in the top bar updates this provider. All
/// auth/user overrides watch it to return the matching dummy data.
final demoScenarioProvider = StateProvider<OnboardingScenario>(
  (ref) => OnboardingScenario.registeredFresh,
);
