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
  testWidgets('rejects a new password shorter than 8 characters', (
    tester,
  ) async {
    await _setSurface(tester);
    var submits = 0;
    await tester.pumpWidget(
      _wrap(
        ChangePasswordForm(
          onSubmit: (_, _) async => submits++,
          onCancel: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(_field('current'), 'oldpass12');
    await tester.enterText(_field('next'), 'short');
    await tester.enterText(_field('confirm'), 'short');
    await tester.tap(find.widgetWithText(ShadButton, 'Update password'));
    await tester.pumpAndSettle();

    expect(submits, 0);
    expect(find.text('At least 8 characters'), findsOneWidget);
  });

  testWidgets('rejects when confirmation does not match', (tester) async {
    await _setSurface(tester);
    var submits = 0;
    await tester.pumpWidget(
      _wrap(
        ChangePasswordForm(
          onSubmit: (_, _) async => submits++,
          onCancel: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(_field('current'), 'oldpass12');
    await tester.enterText(_field('next'), 'newpass12');
    await tester.enterText(_field('confirm'), 'different12');
    await tester.tap(find.widgetWithText(ShadButton, 'Update password'));
    await tester.pumpAndSettle();

    expect(submits, 0);
    expect(find.text('New passwords do not match'), findsOneWidget);
  });

  testWidgets('submits current + new when valid and matching', (tester) async {
    await _setSurface(tester);
    String? gotCurrent;
    String? gotNext;
    await tester.pumpWidget(
      _wrap(
        ChangePasswordForm(
          onSubmit: (current, next) async {
            gotCurrent = current;
            gotNext = next;
          },
          onCancel: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(_field('current'), 'oldpass12');
    await tester.enterText(_field('next'), 'newpass12');
    await tester.enterText(_field('confirm'), 'newpass12');
    await tester.tap(find.widgetWithText(ShadButton, 'Update password'));
    await tester.pumpAndSettle();

    expect(gotCurrent, 'oldpass12');
    expect(gotNext, 'newpass12');
  });
}
