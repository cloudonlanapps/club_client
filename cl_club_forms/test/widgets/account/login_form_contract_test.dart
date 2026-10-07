// Issue 61 points that do not apply to LoginForm: it has no rule across
// fields, no parameter hides or locks a field, it takes no initial values
// (it always opens empty) and it has no optional field.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/account/account_form_validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/account_user_form_harness.dart';
import '../../support/form_harness.dart';

const String _username = LoginFormFields.usernameId;
const String _password = LoginFormFields.passwordId;

Future<LoginFormState> _pump(WidgetTester tester, {bool enabled = true}) async {
  final key = GlobalKey<LoginFormState>();
  await pumpForm(tester, LoginForm(key: key, enabled: enabled));
  return key.currentState!;
}

void main() {
  group('Issue 61: LoginForm', () {
    testWidgets('Issue 61: it shows username and password, each a required '
        'row, the password hidden as typed', (tester) async {
      await _pump(tester);

      expect(rowLabels(tester), ['Username *', 'Password *']);
      expect(fieldIds(tester), [_username, _password]);
      expectLabelsAreRows(tester);
      expectNoHostChrome(tester);
      EditableText editable(String id) => tester.widget<EditableText>(
        find.descendant(
          of: fieldWithId(id),
          matching: find.byType(EditableText),
        ),
      );
      expect(editable(_username).obscureText, isFalse);
      expect(editable(_password).obscureText, isTrue);
    });

    testWidgets('Issue 61: an empty username is refused on its field', (
      tester,
    ) async {
      final state = await _pump(tester);
      await enterField(tester, _password, 'secret');

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();

      expectMessageOn(_username, AccountFormValidators.usernameRequired);
      expect(find.text(AccountFormValidators.passwordRequired), findsNothing);
    });

    testWidgets('Issue 61: a username of spaces is refused on its field', (
      tester,
    ) async {
      final state = await _pump(tester);
      await enterField(tester, _username, '   ');
      await enterField(tester, _password, 'secret');

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();

      expectMessageOn(_username, AccountFormValidators.usernameRequired);
    });

    testWidgets('Issue 61: an empty password is refused on its field, and '
        'the message goes once it is typed', (tester) async {
      final state = await _pump(tester);
      await enterField(tester, _username, 'asha');

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expectMessageOn(_password, AccountFormValidators.passwordRequired);
      expect(find.text(AccountFormValidators.usernameRequired), findsNothing);

      await enterField(tester, _password, 'secret');
      expect(state.validate(), isNotNull);
      await tester.pumpAndSettle();
      expect(find.text(AccountFormValidators.passwordRequired), findsNothing);
    });

    testWidgets('Issue 61: validate returns exactly username and password, '
        'the username trimmed and the password as typed', (tester) async {
      final state = await _pump(tester);
      await enterField(tester, _username, '  asha  ');
      await enterField(tester, _password, '  pass word ');

      final values = state.validate();

      expect(values, {_username: 'asha', _password: '  pass word '});
      expect(values![_username], isA<String>());
      expect(values[_password], isA<String>());
    });

    testWidgets('Issue 61: isDirty follows the username and the password, '
        'and is false again when either is emptied', (tester) async {
      final state = await _pump(tester);
      expect(state.isDirty, isFalse);

      await enterField(tester, _username, 'asha');
      expect(state.isDirty, isTrue);
      await enterField(tester, _username, '');
      expect(state.isDirty, isFalse);

      await enterField(tester, _password, 'secret');
      expect(state.isDirty, isTrue);
      await enterField(tester, _password, '');
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: a refusal of the server shows on the password and '
        'inline, and the form signs in again afterwards', (tester) async {
      final state = await _pump(tester);
      await enterField(tester, _username, 'asha');
      await enterField(tester, _password, 'wrong-one');

      await expectShowsServerErrors(tester, state, _password);

      state.showErrors(
        fieldErrors: const {_password: 'Wrong password.'},
        formError: 'Could not sign in.',
      );
      await tester.pumpAndSettle();
      expectMessageOn(_password, 'Wrong password.');
      expectInlineMessage('Could not sign in.');

      await enterField(tester, _password, 'right-one');
      expect(state.validate(), {_username: 'asha', _password: 'right-one'});
      await tester.pumpAndSettle();
      expect(find.text('Wrong password.'), findsNothing);
      expect(find.text('Could not sign in.'), findsNothing);
    });

    testWidgets('Issue 61: a tap gives the password the focus, and with '
        'enabled off it does not', (tester) async {
      await _pump(tester);
      await tapField(tester, _password);
      expect(hasFocus(tester, _password), isTrue);

      // A new form, so nothing carries over from the one above.
      await tester.pumpWidget(const SizedBox.shrink());
      final state = await _pump(tester, enabled: false);

      expectEveryFieldOff(tester);
      await expectTapsIgnored(tester, [_password]);
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: it fits a phone, with its messages showing', (
      tester,
    ) async {
      final key = GlobalKey<LoginFormState>();
      await expectFitsPhone(tester, LoginForm(key: key));

      expect(key.currentState!.validate(), isNull);
      await tester.pumpAndSettle();

      expect(find.text(AccountFormValidators.usernameRequired), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
