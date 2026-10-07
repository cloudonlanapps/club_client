/// Standalone authentication library for club apps.
///
/// GoRouter-free, callback-driven. The host app must override
/// `serverConfigProvider` in its `ProviderScope` with the API base URL.
library;

// Pure-UI signup primitives live in cl_club_forms; re-export for callers
// that want to embed the form themselves (rare — most use SignupView
// below).
export 'package:cl_club_forms/cl_club_forms.dart'
    show
        SignupForm,
        SignupGender,
        SignupSubmitResult,
        UsernameAvailabilityField;
// Re-export server config so consumers can access it via cl_member_auth
export 'package:cl_server_config/cl_server_config.dart'
    show ServerConfig, serverConfigProvider;

// Models
export 'src/models/auth_session.dart' show AuthSession;
// Permissions
export 'src/permissions/event_permissions.dart'
    show canManageEnrollments, canManageEvent, userAllowedForEvents;
// Providers
export 'src/providers/api_http_client.dart' show apiHttpClientProvider;
export 'src/providers/auth.dart' show AuthNotifier, authStateProvider;
export 'src/providers/client.dart' show ClientNotifier, clientProvider;
export 'src/providers/credential_storage.dart'
    show CredentialStorage, credentialStorageProvider;
export 'src/providers/image_auth_headers.dart' show imageAuthHeadersProvider;
export 'src/providers/token_expiry.dart' show tokenExpiryProvider;
export 'src/providers/token_storage.dart'
    show TokenStorage, tokenStorageProvider;
export 'src/providers/username_availability.dart'
    show UsernameAvailability, usernameAvailabilityProvider;
// Screens (mounted by the host router; each wraps the same-named view)
export 'src/screens/forgot_password_screen.dart' show ForgotPasswordScreen;
export 'src/screens/login_screen.dart' show LoginScreen;
export 'src/screens/signup_screen.dart' show SignupScreen;
export 'src/screens/signup_success_screen.dart' show SignupSuccessScreen;
// Views (no Scaffold — host wraps them in AuthShell at the
// `/auth/**` ShellRoute level)
export 'src/widgets/account_blocked_view.dart' show AccountBlockedView;
export 'src/widgets/account_left_view.dart' show AccountLeftView;
export 'src/widgets/auth_shell.dart' show AuthShell;
export 'src/widgets/change_password_view.dart' show ChangePasswordView;
export 'src/widgets/forgot_password_view.dart' show ForgotPasswordView;
export 'src/widgets/login_view.dart' show LoginView;
export 'src/widgets/session_countdown.dart' show SessionCountdown;
export 'src/widgets/signup_success_view.dart' show SignupSuccessView;
export 'src/widgets/signup_view.dart' show SignupView;
