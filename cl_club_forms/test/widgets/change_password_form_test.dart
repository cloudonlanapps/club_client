import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Widget _wrap(Widget child) => ShadApp(home: Scaffold(body: child));

Finder _field(String id) =>
    find.byWidgetPredicate((w) => w is ShadInputFormField && w.id == id);

Future<GlobalKey<ChangePasswordFormState>> _pump(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1024, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final key = GlobalKey<ChangePasswordFormState>();
  await tester.pumpWidget(_wrap(ChangePasswordForm(key: key)));
  await tester.pumpAndSettle();
  return key;
}

Future<void> _fill(
  WidgetTester tester, {
  required String current,
  required String next,
  required String confirm,
}) async {
  await tester.enterText(_field(ChangePasswordFormFields.currentId), current);
  await tester.enterText(_field(ChangePasswordFormFields.nextId), next);
  await tester.enterText(_field(ChangePasswordFormFields.confirmId), confirm);
}

void main() {
  testWidgets('rejects a new password shorter than 8 characters', (
    tester,
  ) async {
    final key = await _pump(tester);

    await _fill(tester, current: 'oldpass12', next: 'short', confirm: 'short');
    expect(key.currentState!.validate(), isNull);
    await tester.pumpAndSettle();

    expect(find.text('At least 8 characters'), findsOneWidget);
  });

  testWidgets('rejects when confirmation does not match', (tester) async {
    final key = await _pump(tester);

    await _fill(
      tester,
      current: 'oldpass12',
      next: 'newpass12',
      confirm: 'different12',
    );
    expect(key.currentState!.validate(), isNull);
    await tester.pumpAndSettle();

    expect(find.text('New passwords do not match'), findsOneWidget);
  });

  testWidgets('submits current + new when valid and matching', (tester) async {
    final key = await _pump(tester);

    await _fill(
      tester,
      current: 'oldpass12',
      next: 'newpass12',
      confirm: 'newpass12',
    );

    expect(key.currentState!.validate(), {
      ChangePasswordFormFields.currentId: 'oldpass12',
      ChangePasswordFormFields.nextId: 'newpass12',
    });
  });

  testWidgets('Issue 53: ChangePasswordForm has fields only and shows a '
      'refused current password on its field', (tester) async {
    final key = await _pump(tester);

    expect(find.byType(ShadButton), findsNothing);
    expect(find.byType(ShadCard), findsNothing);
    expect(find.text('Change password'), findsNothing);

    key.currentState!.showErrors(
      fieldErrors: {
        ChangePasswordFormFields.currentId: 'Current password is incorrect',
      },
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: _field(ChangePasswordFormFields.currentId),
        matching: find.text('Current password is incorrect'),
      ),
      findsOneWidget,
    );
  });
}
