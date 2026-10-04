import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_member_auth/src/utils/login_error_messages.dart';
import 'package:cl_member_auth/src/widgets/login_view.dart' show LoginViewState;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// An auth notifier whose login is refused with [code], as the server
/// refuses it.
class _RefusingAuth extends AuthNotifier {
  _RefusingAuth(this.code);

  final String code;

  @override
  Future<UserPrivate?> build() async => null;

  @override
  Future<void> login(String username, String password) async {
    state = AsyncError(
      ServerException(
        statusCode: 401,
        code: code,
        message: 'raw server text',
      ),
      StackTrace.current,
    );
  }
}

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

Future<void> _pumpLogin(WidgetTester tester, String code) async {
  await tester.binding.setSurfaceSize(const Size(1024, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  _ignoreOverflow();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authStateProvider.overrideWith(() => _RefusingAuth(code))],
      child: ShadApp(
        home: ShadToaster(
          child: Scaffold(
            body: LoginView(
              onLoginSuccess: () {},
              onNavigateToForgotPassword: () {},
              onNavigateToSignup: () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester
      .state<LoginViewState>(find.byType(LoginView))
      .handleLogin('member', 'password');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets(
    'Issue 157: a member who has left sees the account-left message',
    (tester) async {
      await _pumpLogin(tester, SdkErrorCode.accountLeft);

      expect(find.byType(AccountLeftView), findsOneWidget);
      expect(
        find.text(LoginErrorMessages.accountLeft),
        findsWidgets,
        reason: 'the card and the toast both say it',
      );
      expect(find.textContaining('raw server text'), findsNothing);
      expect(find.textContaining('ServerException'), findsNothing);
    },
  );

  testWidgets(
    'Issue 157: an unmapped refusal shows fixed text, not the raw error',
    (tester) async {
      await _pumpLogin(tester, 'SOMETHING_NEW');

      expect(find.text(LoginErrorMessages.fallback), findsWidgets);
      expect(find.textContaining('raw server text'), findsNothing);
      expect(find.textContaining('ServerException'), findsNothing);
    },
  );

  testWidgets('Issue 157: wrong credentials keep their message', (
    tester,
  ) async {
    await _pumpLogin(tester, SdkErrorCode.invalidCredentials);

    expect(find.text('Incorrect username or password'), findsWidgets);
  });
}
