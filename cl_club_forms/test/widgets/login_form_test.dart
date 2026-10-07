import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Widget _wrap(Widget child) => ShadApp(home: Scaffold(body: child));

Finder _field(String id) =>
    find.byWidgetPredicate((w) => w is ShadInputFormField && w.id == id);

void main() {
  testWidgets('blocks submit until username and password are present', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var submitted = false;
    String? gotUser;
    await tester.pumpWidget(
      _wrap(
        LoginForm(
          onSubmit: (u, p) async {
            submitted = true;
            gotUser = u;
          },
          onForgotPassword: () {},
          onSignUp: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Empty form — validation blocks the callback.
    await tester.tap(find.widgetWithText(ShadButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(submitted, isFalse);
    expect(find.text('Username is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);

    // Fill both — callback fires with the trimmed username.
    await tester.enterText(_field('username'), '  asha  ');
    await tester.enterText(_field('password'), 'secret');
    await tester.tap(find.widgetWithText(ShadButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(submitted, isTrue);
    expect(gotUser, 'asha');
  });
}
