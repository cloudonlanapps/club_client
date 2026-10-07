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
    final key = GlobalKey<LoginFormState>();
    await tester.pumpWidget(_wrap(LoginForm(key: key)));
    await tester.pumpAndSettle();

    // Empty form — validation gives the host nothing to submit.
    expect(key.currentState!.validate(), isNull);
    await tester.pumpAndSettle();
    expect(find.text('Username is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);

    // Fill both — the values come back with the username trimmed.
    await tester.enterText(_field(LoginFormFields.usernameId), '  asha  ');
    await tester.enterText(_field(LoginFormFields.passwordId), 'secret');
    expect(key.currentState!.validate(), {
      LoginFormFields.usernameId: 'asha',
      LoginFormFields.passwordId: 'secret',
    });
  });

  testWidgets('Issue 53: LoginForm has fields only, each in a labelled row '
      'marked required', (tester) async {
    await tester.pumpWidget(_wrap(const LoginForm()));
    await tester.pumpAndSettle();

    expect(find.byType(ShadButton), findsNothing);
    expect(find.text('Sign in'), findsNothing);
    expect(find.text('Username *'), findsOneWidget);
    expect(find.text('Password *'), findsOneWidget);
  });

  testWidgets('Issue 53: LoginForm with enabled off takes no input', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const LoginForm(enabled: false)));
    await tester.pumpAndSettle();

    for (final id in [LoginFormFields.usernameId, LoginFormFields.passwordId]) {
      expect(tester.widget<ShadInputFormField>(_field(id)).enabled, isFalse);
    }
  });
}
