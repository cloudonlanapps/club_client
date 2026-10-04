import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

Widget _wrap(Widget child) => ShadApp(home: Scaffold(body: child));

Finder _field(String id) =>
    find.byWidgetPredicate((w) => w is ShadInputFormField && w.id == id);

Future<void> _setSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1024, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  testWidgets('Issue 746: rejects an empty email', (tester) async {
    await _setSurface(tester);
    var submits = 0;
    await tester.pumpWidget(
      _wrap(
        ForgotPasswordForm(
          onSubmit: (_) async => submits++,
          onBack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ShadButton, 'Send reset email'));
    await tester.pumpAndSettle();

    expect(submits, 0);
    expect(find.text('Email is required'), findsOneWidget);
  });

  testWidgets('Issue 746: rejects a malformed email', (tester) async {
    await _setSurface(tester);
    var submits = 0;
    await tester.pumpWidget(
      _wrap(
        ForgotPasswordForm(
          onSubmit: (_) async => submits++,
          onBack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(_field('email'), 'not-an-email');
    await tester.tap(find.widgetWithText(ShadButton, 'Send reset email'));
    await tester.pumpAndSettle();

    expect(submits, 0);
    expect(find.text('Enter a valid email'), findsOneWidget);
  });

  testWidgets('Issue 746: submits the trimmed email when valid', (
    tester,
  ) async {
    await _setSurface(tester);
    String? gotEmail;
    await tester.pumpWidget(
      _wrap(
        ForgotPasswordForm(
          onSubmit: (email) async => gotEmail = email,
          onBack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(_field('email'), '  member@example.com  ');
    await tester.tap(find.widgetWithText(ShadButton, 'Send reset email'));
    await tester.pumpAndSettle();

    expect(gotEmail, 'member@example.com');
  });

  testWidgets('Issue 746: Back to sign in invokes onBack', (tester) async {
    await _setSurface(tester);
    var backs = 0;
    await tester.pumpWidget(
      _wrap(
        ForgotPasswordForm(
          onSubmit: (_) async {},
          onBack: () => backs++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ShadButton, 'Back to sign in'));
    await tester.pumpAndSettle();

    expect(backs, 1);
  });
}
