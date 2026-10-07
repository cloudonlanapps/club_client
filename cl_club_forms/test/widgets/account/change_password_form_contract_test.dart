// Issue 61 points that do not apply to ChangePasswordForm: no parameter
// hides or locks a field, it takes no initial values (it always opens
// empty) and it has no optional field.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/account/account_form_validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/account_user_form_harness.dart';
import '../../support/form_harness.dart';

const String _current = ChangePasswordFormFields.currentId;
const String _next = ChangePasswordFormFields.nextId;
const String _confirm = ChangePasswordFormFields.confirmId;

Future<ChangePasswordFormState> _pump(
  WidgetTester tester, {
  bool enabled = true,
}) async {
  final key = GlobalKey<ChangePasswordFormState>();
  await pumpForm(tester, ChangePasswordForm(key: key, enabled: enabled));
  return key.currentState!;
}

Future<void> _fill(
  WidgetTester tester, {
  String current = 'old-password',
  String next = 'new-password',
  String confirm = 'new-password',
}) async {
  await enterField(tester, _current, current);
  await enterField(tester, _next, next);
  await enterField(tester, _confirm, confirm);
}

void main() {
  group('Issue 61: ChangePasswordForm', () {
    testWidgets('Issue 61: it shows the current password, the new one and '
        'its confirmation, each a required row and hidden as typed', (
      tester,
    ) async {
      await _pump(tester);

      expect(rowLabels(tester), [
        'Current password *',
        'New password *',
        'Confirm new password *',
      ]);
      expect(fieldIds(tester), [_current, _next, _confirm]);
      expectLabelsAreRows(tester);
      expectNoHostChrome(tester);
      expect(
        tester
            .widgetList<EditableText>(find.byType(EditableText))
            .map((editable) => editable.obscureText),
        [true, true, true],
      );
    });

    testWidgets('Issue 61: an empty current password is refused on its '
        'field', (tester) async {
      final state = await _pump(tester);
      await _fill(tester, current: '');

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();

      expectMessageOn(_current, AccountFormValidators.currentPasswordRequired);
      expect(
        find.text(AccountFormValidators.newPasswordRequired),
        findsNothing,
      );
      expect(
        find.text(AccountFormValidators.confirmationRequired),
        findsNothing,
      );
    });

    testWidgets('Issue 61: an empty new password is refused on its field', (
      tester,
    ) async {
      final state = await _pump(tester);
      await _fill(tester, next: '');

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();

      expectMessageOn(_next, AccountFormValidators.newPasswordRequired);
    });

    testWidgets('Issue 61: a new password of seven characters is refused on '
        'its field, and one of eight is taken', (tester) async {
      final state = await _pump(tester);
      await _fill(tester, next: '1234567', confirm: '1234567');

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expectMessageOn(_next, AccountFormValidators.newPasswordTooShort);

      await _fill(tester, next: '12345678', confirm: '12345678');
      expect(state.validate(), {_current: 'old-password', _next: '12345678'});
      await tester.pumpAndSettle();
      expect(
        find.text(AccountFormValidators.newPasswordTooShort),
        findsNothing,
      );
    });

    testWidgets('Issue 61: an empty confirmation is refused on its field, '
        'not as a mismatch', (tester) async {
      final state = await _pump(tester);
      await _fill(tester, confirm: '');

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();

      expectMessageOn(_confirm, AccountFormValidators.confirmationRequired);
      expect(find.text(AccountFormValidators.newPasswordsDiffer), findsNothing);
    });

    testWidgets('Issue 61: two new passwords that differ are refused '
        'inline, and taken once they are the same', (tester) async {
      final state = await _pump(tester);
      await _fill(tester, confirm: 'new-passworD');

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expectInlineMessage(AccountFormValidators.newPasswordsDiffer);

      await enterField(tester, _confirm, 'new-password');
      expect(state.validate(), isNotNull);
      await tester.pumpAndSettle();
      expect(find.text(AccountFormValidators.newPasswordsDiffer), findsNothing);
    });

    testWidgets('Issue 61: validate returns exactly the current and the new '
        'password as typed, without the confirmation', (tester) async {
      final state = await _pump(tester);
      await _fill(
        tester,
        current: ' old password ',
        next: ' new password ',
        confirm: ' new password ',
      );

      final values = state.validate();

      expect(values, {_current: ' old password ', _next: ' new password '});
      expect(values![_current], isA<String>());
      expect(values[_next], isA<String>());
    });

    testWidgets('Issue 61: isDirty follows each of the three fields, and is '
        'false again when it is emptied', (tester) async {
      final state = await _pump(tester);
      expect(state.isDirty, isFalse);

      for (final id in [_current, _next, _confirm]) {
        await enterField(tester, id, 'something');
        expect(state.isDirty, isTrue, reason: id);
        await enterField(tester, id, '');
        expect(state.isDirty, isFalse, reason: id);
      }
    });

    testWidgets('Issue 61: a refused current password shows on its field and '
        'inline, and the form saves again once it is retyped', (tester) async {
      final state = await _pump(tester);
      await _fill(tester);

      await expectShowsServerErrors(tester, state, _current);

      state.showErrors(
        fieldErrors: const {_current: 'Current password is incorrect'},
        formError: 'Could not change the password.',
      );
      await tester.pumpAndSettle();
      expectMessageOn(_current, 'Current password is incorrect');
      expectInlineMessage('Could not change the password.');

      await enterField(tester, _current, 'the-right-one');
      expect(state.validate(), {
        _current: 'the-right-one',
        _next: 'new-password',
      });
      await tester.pumpAndSettle();
      expect(find.text('Current password is incorrect'), findsNothing);
      expect(find.text('Could not change the password.'), findsNothing);
    });

    testWidgets('Issue 61: a tap gives a field the focus, and with enabled '
        'off it does not', (tester) async {
      await _pump(tester);
      await tapField(tester, _next);
      expect(hasFocus(tester, _next), isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      final state = await _pump(tester, enabled: false);

      expectEveryFieldOff(tester);
      await expectTapsIgnored(tester, [_next, _confirm]);
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: it fits a phone, with every message showing', (
      tester,
    ) async {
      final key = GlobalKey<ChangePasswordFormState>();
      await expectFitsPhone(tester, ChangePasswordForm(key: key));

      expect(key.currentState!.validate(), isNull);
      await tester.pumpAndSettle();
      expect(
        find.text(AccountFormValidators.confirmationRequired),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await _fill(tester, confirm: 'another-password');
      expect(key.currentState!.validate(), isNull);
      await tester.pumpAndSettle();
      expect(
        find.text(AccountFormValidators.newPasswordsDiffer),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
