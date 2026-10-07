import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Widget _wrap(Widget child) => ShadApp(home: Scaffold(body: child));

Finder _email() => find.byWidgetPredicate(
  (w) => w is ShadInputFormField && w.id == ForgotPasswordFormFields.emailId,
);

Future<GlobalKey<ForgotPasswordFormState>> _pump(
  WidgetTester tester, {
  VoidCallback? onSubmitted,
}) async {
  await tester.binding.setSurfaceSize(const Size(1024, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final key = GlobalKey<ForgotPasswordFormState>();
  await tester.pumpWidget(
    _wrap(ForgotPasswordForm(key: key, onSubmitted: onSubmitted)),
  );
  await tester.pumpAndSettle();
  return key;
}

void main() {
  testWidgets('Issue 746: rejects an empty email', (tester) async {
    final key = await _pump(tester);

    expect(key.currentState!.validate(), isNull);
    await tester.pumpAndSettle();

    expect(find.text('Email is required'), findsOneWidget);
  });

  testWidgets('Issue 746: rejects a malformed email', (tester) async {
    final key = await _pump(tester);

    await tester.enterText(_email(), 'not-an-email');
    expect(key.currentState!.validate(), isNull);
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email'), findsOneWidget);
  });

  testWidgets('Issue 746: submits the trimmed email when valid', (
    tester,
  ) async {
    final key = await _pump(tester);

    await tester.enterText(_email(), '  member@example.com  ');

    expect(key.currentState!.validate(), {
      ForgotPasswordFormFields.emailId: 'member@example.com',
    });
  });

  testWidgets('Issue 53: ForgotPasswordForm has its field only, and Enter '
      'calls onSubmitted', (tester) async {
    var submitted = 0;
    await _pump(tester, onSubmitted: () => submitted++);

    expect(find.byType(ShadButton), findsNothing);
    expect(find.text('Reset password'), findsNothing);
    expect(find.text('Email *'), findsOneWidget);

    await tester.enterText(_email(), 'member@example.com');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(submitted, 1);
  });
}
