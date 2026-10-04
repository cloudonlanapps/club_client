import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:cl_member_onboarding/cl_member_onboarding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../data/dummy_data.dart';
import '../providers/demo_scenario.dart';

/// One-screen demo host: a scenario selector at the top, the onboarding
/// shell below. Toggling the scenario rebuilds `authStateProvider` (via
/// `DummyAuthNotifier` watching `demoScenarioProvider`), which then
/// drives variant selection inside `OnboardingWelcomeView`.
///
/// The two onboarding routes are simulated with a tab toggle so both
/// surfaces can be inspected without a router.
class OnboardingDemoShell extends ConsumerStatefulWidget {
  const OnboardingDemoShell({
    required this.onThemeToggle,
    required this.themeMode,
    super.key,
  });

  final VoidCallback onThemeToggle;
  final ThemeMode themeMode;

  @override
  ConsumerState<OnboardingDemoShell> createState() =>
      _OnboardingDemoShellState();
}

enum _DemoRoute { welcome, submitDocuments }

class _OnboardingDemoShellState extends ConsumerState<OnboardingDemoShell> {
  _DemoRoute _route = _DemoRoute.welcome;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final scenario = ref.watch(demoScenarioProvider);
    final user = ref.watch(authStateProvider).valueOrNull;

    return Column(
      children: [
        _ControlBar(
          scenario: scenario,
          route: _route,
          onScenarioChanged: (next) {
            ref.read(demoScenarioProvider.notifier).state = next;
            // Welcome handles every variant; jump there on change so the
            // chosen variant is the first thing you see.
            setState(() => _route = _DemoRoute.welcome);
          },
          onRouteChanged: (next) => setState(() => _route = next),
          onThemeToggle: widget.onThemeToggle,
          themeMode: widget.themeMode,
        ),
        Container(
          height: 1,
          color: theme.colorScheme.border,
        ),
        Expanded(
          child: ColoredBox(
            color: theme.colorScheme.background,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.card,
                      border: Border.all(color: theme.colorScheme.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: user == null
                          ? const Center(child: CircularProgressIndicator())
                          : _buildOnboarding(_route),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOnboarding(_DemoRoute route) {
    switch (route) {
      case _DemoRoute.welcome:
        return OnboardingShell(
          title: (u) => 'Welcome ${u.displayName}',
          child: OnboardingWelcomeScreen(
            onContinue: () =>
                setState(() => _route = _DemoRoute.submitDocuments),
            onHome: () => setState(() => _route = _DemoRoute.welcome),
          ),
        );
      case _DemoRoute.submitDocuments:
        return OnboardingShell(
          title: (_) => 'Submit documents',
          onBack: () => setState(() => _route = _DemoRoute.welcome),
          child: OnboardingSubmitDocumentsScreen(
            onHome: () => setState(() => _route = _DemoRoute.welcome),
          ),
        );
    }
  }
}

class _ControlBar extends StatelessWidget {
  const _ControlBar({
    required this.scenario,
    required this.route,
    required this.onScenarioChanged,
    required this.onRouteChanged,
    required this.onThemeToggle,
    required this.themeMode,
  });

  final OnboardingScenario scenario;
  final _DemoRoute route;
  final ValueChanged<OnboardingScenario> onScenarioChanged;
  final ValueChanged<_DemoRoute> onRouteChanged;
  final VoidCallback onThemeToggle;
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Container(
      color: theme.colorScheme.card,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SafeArea(
        bottom: false,
        child: Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Scenario: ',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                DropdownButton<OnboardingScenario>(
                  value: scenario,
                  isDense: true,
                  items: OnboardingScenario.values
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.label),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onScenarioChanged(v);
                  },
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Route: ',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                _RouteToggle(
                  route: route,
                  onChanged: onRouteChanged,
                ),
              ],
            ),
            IconButton(
              tooltip: 'Toggle theme',
              onPressed: onThemeToggle,
              icon: Icon(
                themeMode == ThemeMode.dark
                    ? LucideIcons.sun
                    : LucideIcons.moon,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteToggle extends StatelessWidget {
  const _RouteToggle({required this.route, required this.onChanged});

  final _DemoRoute route;
  final ValueChanged<_DemoRoute> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_DemoRoute>(
      segments: const [
        ButtonSegment(
          value: _DemoRoute.welcome,
          label: Text('Welcome'),
        ),
        ButtonSegment(
          value: _DemoRoute.submitDocuments,
          label: Text('Submit docs'),
        ),
      ],
      selected: {route},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
    );
  }
}
