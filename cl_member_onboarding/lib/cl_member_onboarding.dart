/// Onboarding screens for a club app.
///
/// Two routes, one shell, one welcome view with three status-driven
/// variants. See [`CLAUDE.md`](../CLAUDE.md) for the topology.
library;

export 'src/models/onboarding_routes.dart'
    show
        allowedOnboardingPaths,
        onboardingSubmitDocumentsPath,
        onboardingWelcomePath;
export 'src/screens/onboarding_submit_documents_screen.dart'
    show OnboardingSubmitDocumentsScreen;
export 'src/screens/onboarding_welcome_screen.dart'
    show OnboardingWelcomeScreen;
export 'src/widgets/onboarding_shell.dart' show OnboardingShell;
