import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [
        serverConfigProvider.overrideWithValue(
          const ServerConfig(baseUrl: 'https://api.example.org/v1'),
        ),
      ],
      child: const ExampleApp(),
    ),
  );
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShadApp(title: 'cl_member_auth Example', home: AuthGate());
  }
}

/// Watches [authStateProvider] and switches between login and home.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);

    return auth.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(
        body: LoginView(
          onLoginSuccess: () {},
          onNavigateToForgotPassword: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ForgotPasswordPage()),
          ),
          onNavigateToSignup: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const SignupPage())),
        ),
      ),
      data: (user) {
        if (user == null) {
          return Scaffold(
            body: LoginView(
              onLoginSuccess: () {},
              onNavigateToForgotPassword: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ForgotPasswordPage(),
                ),
              ),
              onNavigateToSignup: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SignupPage()),
              ),
            ),
          );
        }
        return const HomePage();
      },
    );
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_outline),
            tooltip: 'Change password',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ChangePasswordPage(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: const Center(child: Text('Authenticated!')),
    );
  }
}

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: SignupView(
        onSignupSuccess: () => Navigator.of(context).pop(),
        onNavigateToLogin: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: ForgotPasswordView(
        onNavigateToLogin: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class ChangePasswordPage extends StatelessWidget {
  const ChangePasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: ChangePasswordView(
        onSuccess: () => Navigator.of(context).pop(),
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }
}
