import 'package:cl_club_forms/cl_club_forms.dart'
    show LoginForm, LoginFormFields;
import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_member_auth/src/utils/login_error_messages.dart';
import 'package:cl_member_auth/src/widgets/login_view.dart' show LoginViewState;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
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

/// An auth notifier whose login fails with [failure] after loading, as the
/// real one does; null signs nobody in and fails nothing.
class _FailingAuth extends AuthNotifier {
  _FailingAuth(this.failure);

  final Object? failure;

  @override
  Future<UserPrivate?> build() async => null;

  @override
  Future<void> login(String username, String password) async {
    final failure = this.failure;
    if (failure == null) return;
    state = const AsyncLoading();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    state = AsyncError(failure, StackTrace.current);
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

  group('Issue 97: LoginView shows a failed sign-in where it belongs', () {
    Future<void> pump(
      WidgetTester tester, {
      AuthNotifier Function()? auth,
      Future<void> Function(String, String)? onLogin,
    }) async {
      await tester.binding.setSurfaceSize(const Size(1024, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      _ignoreOverflow();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(auth ?? () => _FailingAuth(null)),
          ],
          child: ShadApp(
            home: ShadToaster(
              child: Scaffold(
                body: LoginView(
                  onLoginSuccess: () {},
                  onNavigateToForgotPassword: () {},
                  onNavigateToSignup: () {},
                  onLogin: onLogin,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> signIn(WidgetTester tester) async {
      await tester.enterText(_field(LoginFormFields.usernameId), 'asha');
      await tester.enterText(_field(LoginFormFields.passwordId), 'secret');
      await tester.tap(find.widgetWithText(ShadButton, 'Sign in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    void expectFormOnWithWhatWasTyped(WidgetTester tester) {
      final username = tester.widget<ShadInputFormField>(
        _field(LoginFormFields.usernameId),
      );
      expect(username.enabled, isTrue);
      expect(find.text('asha'), findsOneWidget);
      expect(
        tester
            .widget<ShadButton>(find.widgetWithText(ShadButton, 'Sign in'))
            .onPressed,
        isNotNull,
      );
    }

    testWidgets('Issue 97: a wrong username or password shows inline in '
        'the form, with no toast, and the form keeps what was typed', (
      tester,
    ) async {
      await pump(
        tester,
        auth: () => _FailingAuth(
          const ServerException(
            statusCode: 401,
            code: SdkErrorCode.invalidCredentials,
            message: 'raw server text',
          ),
        ),
      );
      await signIn(tester);

      expect(
        find.descendant(
          of: find.byType(LoginForm),
          matching: find.text(LoginErrorMessages.invalidCredentials),
        ),
        findsOneWidget,
      );
      expect(find.text(LoginErrorMessages.invalidCredentials), findsOneWidget);
      expect(find.byType(ShadToast), findsNothing);
      expectFormOnWithWhatWasTyped(tester);
    });

    testWidgets('Issue 97: a server that cannot be reached is a toast, not '
        'a message in the form', (tester) async {
      await pump(
        tester,
        auth: () => _FailingAuth(http.ClientException('connection closed')),
      );
      await signIn(tester);

      expect(find.byType(ShadToast), findsOneWidget);
      expect(find.text(LoginErrorMessages.unreachable), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(LoginForm),
          matching: find.text(LoginErrorMessages.unreachable),
        ),
        findsNothing,
      );
      expectFormOnWithWhatWasTyped(tester);
    });

    testWidgets('Issue 97: a sign-in that throws leaves the form on, with '
        'a message', (tester) async {
      await pump(
        tester,
        onLogin: (_, _) async => throw StateError('raw failure text'),
      );
      await signIn(tester);

      expect(find.text(LoginErrorMessages.fallback), findsOneWidget);
      expect(find.textContaining('raw failure text'), findsNothing);
      expectFormOnWithWhatWasTyped(tester);
    });
  });
}
