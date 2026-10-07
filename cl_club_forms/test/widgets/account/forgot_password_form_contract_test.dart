// Issue 61 points that do not apply to ForgotPasswordForm: it has one
// field, so no rule across fields; no parameter hides or locks it; it takes
// no initial values (it always opens empty) and it has no optional field.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/account_user_form_harness.dart';
import '../../support/form_harness.dart';

const String _email = ForgotPasswordFormFields.emailId;

Future<ForgotPasswordFormState> _pump(
  WidgetTester tester, {
  bool enabled = true,
  VoidCallback? onSubmitted,
}) async {
  final key = GlobalKey<ForgotPasswordFormState>();
  await pumpForm(
    tester,
    ForgotPasswordForm(key: key, enabled: enabled, onSubmitted: onSubmitted),
  );
  return key.currentState!;
}

void main() {
  group('Issue 61: ForgotPasswordForm', () {
    testWidgets('Issue 61: it shows the email alone, a required row with '
        'its hint', (tester) async {
      await _pump(tester);

      expect(rowLabels(tester), ['Email *']);
      expect(fieldIds(tester), [_email]);
      expect(find.text('you@example.com'), findsOneWidget);
      expectLabelsAreRows(tester);
      expectNoHostChrome(tester);
    });

    testWidgets('Issue 61: an empty email is refused on its field', (
      tester,
    ) async {
      final state = await _pump(tester);

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();

      expectMessageOn(_email, 'Email is required');
    });

    testWidgets('Issue 61: an email of spaces is refused on its field', (
      tester,
    ) async {
      final state = await _pump(tester);
      await enterField(tester, _email, '   ');

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();

      expectMessageOn(_email, 'Email is required');
    });

    testWidgets('Issue 61: an email without @ is refused on its field, and '
        'the message goes once it is put right', (tester) async {
      final state = await _pump(tester);
      await enterField(tester, _email, 'member.example.com');

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expectMessageOn(_email, 'Enter a valid email');

      await enterField(tester, _email, 'member@example.com');
      expect(state.validate(), isNotNull);
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid email'), findsNothing);
    });

    testWidgets('Issue 61: validate returns exactly the email, a trimmed '
        'String', (tester) async {
      final state = await _pump(tester);
      await enterField(tester, _email, '\tmember@example.com  ');

      final values = state.validate();

      expect(values, {_email: 'member@example.com'});
      expect(values![_email], isA<String>());
    });

    testWidgets('Issue 61: isDirty is true once an email is typed and false '
        'again when it is emptied', (tester) async {
      final state = await _pump(tester);
      expect(state.isDirty, isFalse);

      await enterField(tester, _email, 'member@example.com');
      expect(state.isDirty, isTrue);

      await enterField(tester, _email, '');
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: a refusal of the server shows on the email and '
        'inline, and the form sends again afterwards', (tester) async {
      final state = await _pump(tester);
      await enterField(tester, _email, 'member@example.com');

      await expectShowsServerErrors(tester, state, _email);

      state.showErrors(
        fieldErrors: const {_email: 'Too many requests for this address.'},
        formError: 'Could not send the email.',
      );
      await tester.pumpAndSettle();
      expectMessageOn(_email, 'Too many requests for this address.');
      expectInlineMessage('Could not send the email.');

      expect(state.validate(), {_email: 'member@example.com'});
      await tester.pumpAndSettle();
      expect(find.text('Too many requests for this address.'), findsNothing);
      expect(find.text('Could not send the email.'), findsNothing);
    });

    testWidgets('Issue 61: Enter in the field is harmless when the host '
        'listens for nothing', (tester) async {
      final state = await _pump(tester);
      await enterField(tester, _email, 'member@example.com');

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(state.validate(), {_email: 'member@example.com'});
    });

    testWidgets('Issue 61: with enabled off the email is off', (tester) async {
      final state = await _pump(tester, enabled: false);

      expectEveryFieldOff(tester);
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: it fits a phone, with its message showing', (
      tester,
    ) async {
      final key = GlobalKey<ForgotPasswordFormState>();
      await expectFitsPhone(tester, ForgotPasswordForm(key: key));

      expect(key.currentState!.validate(), isNull);
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
