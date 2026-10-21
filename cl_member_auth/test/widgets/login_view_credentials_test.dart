import 'package:cl_club_forms/cl_club_forms.dart' show LoginFormFields;
import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_member_auth/src/constants/auth_view_strings.dart';
import 'package:cl_member_auth/src/utils/login_error_messages.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

final _asha = UserPrivate(
  username: 'asha',
  displayName: 'Asha',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(),
  createdAtUtc: DateTime.utc(2024),
);

/// Signs in whoever asks; whether the credentials were saved is [saved].
class _SigningInAuth extends AuthNotifier {
  _SigningInAuth({required this.saved});

  final bool saved;

  @override
  bool get credentialsSaved => saved;

  @override
  Future<UserPrivate?> build() async => null;

  @override
  Future<void> login(String username, String password) async {
    state = const AsyncLoading();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    state = AsyncData(_asha);
  }
}

Finder _field(String id) =>
    find.byWidgetPredicate((w) => w is ShadInputFormField && w.id == id);

/// The test font is wider than any real one, so the login form's link row
/// overflows its 420-pixel column here. That is layout noise, not what these
/// tests assert; every other error still fails the test.
void _ignoreOverflow() {
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    original?.call(details);
  };
  addTearDown(() => FlutterError.onError = original);
}

void main() {
  Future<int> signIn(WidgetTester tester, {required bool saved}) async {
    await tester.binding.setSurfaceSize(const Size(1024, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    _ignoreOverflow();
    var successes = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => _SigningInAuth(saved: saved)),
        ],
        child: ShadApp(
          home: ShadToaster(
            child: Scaffold(
              body: LoginView(
                onLoginSuccess: () => successes++,
                onNavigateToForgotPassword: () {},
                onNavigateToSignup: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(_field(LoginFormFields.usernameId), 'asha');
    await tester.enterText(_field(LoginFormFields.passwordId), 'secret');
    await tester.tap(find.widgetWithText(ShadButton, 'Sign in'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    return successes;
  }

  group('Issue 146: credentials the browser cannot keep', () {
    testWidgets('Issue 146: the member is signed in and told they will '
        'sign in again next time, never that sign-in failed', (tester) async {
      final successes = await signIn(tester, saved: false);

      expect(successes, greaterThan(0));
      expect(find.text(AuthViewStrings.signInNotKept), findsOneWidget);
      expect(find.text(LoginErrorMessages.fallback), findsNothing);
    });

    testWidgets('Issue 146: credentials that are kept show no notice', (
      tester,
    ) async {
      final successes = await signIn(tester, saved: true);

      expect(successes, greaterThan(0));
      expect(find.text(AuthViewStrings.signInNotKept), findsNothing);
    });
  });

  testWidgets('Issue 199: a sign-in from the form calls onLoginSuccess once', (
    tester,
  ) async {
    expect(await signIn(tester, saved: true), 1);
  });

  testWidgets('Issue 199: a sign-in whose credentials are not kept calls '
      'onLoginSuccess once, after the notice', (tester) async {
    expect(await signIn(tester, saved: false), 1);
    expect(find.text(AuthViewStrings.signInNotKept), findsOneWidget);
  });
}
