import 'package:cl_club_forms/cl_club_forms.dart'
    show ChangePasswordFormFields, ForgotPasswordFormFields, LoginFormFields;
import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _reason = 'Value is not accepted here';

/// A schema rejection (422) naming the body field [name], with [_reason].
ServerException _rejection(String name) => ServerException(
  statusCode: 422,
  code: SdkErrorCode.validationError,
  message: _reason,
  details: {
    ServerException.refusedFieldsKey: [
      {
        'loc': ['body', name],
        'msg': _reason,
      },
    ],
  },
);

/// Nobody is signed in.
class _NoAuth extends AuthNotifier {
  @override
  Future<UserPrivate?> build() async => null;
}

Finder _field(String id) =>
    find.byWidgetPredicate((w) => w is ShadInputFormField && w.id == id);

/// The schema's reason, shown on the field [id] and nowhere else.
void _expectOnField(String id) {
  expect(
    find.descendant(of: _field(id), matching: find.text(_reason)),
    findsOneWidget,
  );
  expect(find.text(_reason), findsOneWidget);
  expect(find.byType(ShadToast), findsNothing);
}

Future<void> _pump(WidgetTester tester, Widget view) async {
  await tester.binding.setSurfaceSize(const Size(1024, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  // The test font is wider than any real one, so a row may overflow here.
  final onError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    onError?.call(details);
  };
  addTearDown(() => FlutterError.onError = onError);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authStateProvider.overrideWith(_NoAuth.new)],
      child: ShadApp(
        home: ShadToaster(child: Scaffold(body: view)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 114: a schema rejection shows on the field it names', () {
    testWidgets('Issue 114: forgot password shows it on the email', (
      tester,
    ) async {
      await _pump(
        tester,
        ForgotPasswordView(
          onNavigateToLogin: () {},
          onResetPassword: (_) async => throw _rejection('email'),
        ),
      );

      await tester.enterText(
        _field(ForgotPasswordFormFields.emailId),
        'member@example.com',
      );
      await tester.tap(find.widgetWithText(ShadButton, 'Send reset email'));
      await tester.pumpAndSettle();

      _expectOnField(ForgotPasswordFormFields.emailId);
      expect(find.text('Check your email'), findsNothing);
    });

    testWidgets('Issue 114: change password shows it on the new password', (
      tester,
    ) async {
      await _pump(
        tester,
        ChangePasswordView(
          onSuccess: () {},
          onCancel: () {},
          onChangePassword:
              ({required currentPassword, required newPassword}) async =>
                  throw _rejection('newPassword'),
        ),
      );

      await tester.enterText(
        _field(ChangePasswordFormFields.currentId),
        'old-one',
      );
      await tester.enterText(
        _field(ChangePasswordFormFields.nextId),
        'new-pass-1',
      );
      await tester.enterText(
        _field(ChangePasswordFormFields.confirmId),
        'new-pass-1',
      );
      await tester.tap(find.widgetWithText(ShadButton, 'Update password'));
      await tester.pumpAndSettle();

      _expectOnField(ChangePasswordFormFields.nextId);
    });

    testWidgets('Issue 114: login shows it on the username', (tester) async {
      await _pump(
        tester,
        LoginView(
          onLoginSuccess: () {},
          onNavigateToForgotPassword: () {},
          onNavigateToSignup: () {},
          onLogin: (_, _) async => throw _rejection('username'),
        ),
      );

      await tester.enterText(_field(LoginFormFields.usernameId), 'asha');
      await tester.enterText(_field(LoginFormFields.passwordId), 'secret');
      await tester.tap(find.widgetWithText(ShadButton, 'Sign in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      _expectOnField(LoginFormFields.usernameId);
    });
  });
}
