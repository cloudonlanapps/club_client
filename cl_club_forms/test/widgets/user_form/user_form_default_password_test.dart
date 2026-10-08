// Issue 70, UserForm: ticking "Use default password" again takes the typed
// password out of the form.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/account_user_form_harness.dart';
import '../../support/form_harness.dart';
import 'user_form_create_pump.dart';

const String _password = UserFormFields.passwordId;
const String _confirm = UserFormFields.confirmPasswordId;
const String _useDefault = UserFormFields.useDefaultPasswordId;

void main() {
  group('Issue 70: UserForm, the default password ticked again', () {
    testWidgets('Issue 70: the typed password and its confirmation are '
        'cleared, and the form is not dirty', (tester) async {
      final state = await pumpCreate(tester);
      expect(state.isDirty, isFalse);

      await typeOwnPassword(tester);
      expect(heldValue(state, _password), 'secret-password');
      expect(heldValue(state, _confirm), 'secret-password');
      expect(state.isDirty, isTrue);

      await tapCheckbox(tester, _useDefault);

      expect(fieldWithId(_password), findsNothing);
      expect(heldValue(state, _useDefault), isTrue);
      expect(heldValue(state, _password), '');
      expect(heldValue(state, _confirm), '');
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 70: the values of a valid form hold no password', (
      tester,
    ) async {
      final state = await pumpCreate(tester);
      await fillCreate(tester, state);
      await typeOwnPassword(tester);
      await tapCheckbox(tester, _useDefault);

      final values = state.validate();

      expect(values, isNotNull);
      expect(values![_useDefault], isTrue);
      expect(values[_password], '');
      expect(values[_confirm], '');
    });

    testWidgets('Issue 70: unticked once more, the password fields open '
        'empty and are asked for again', (tester) async {
      final state = await pumpCreate(tester);
      await fillCreate(tester, state);
      await typeOwnPassword(tester);
      await tapCheckbox(tester, _useDefault);

      await tapCheckbox(tester, _useDefault);

      expect(editableOf(tester, _password).controller.text, '');
      expect(editableOf(tester, _confirm).controller.text, '');
      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expectMessageOn(_password, 'Password is required');
    });

    testWidgets('Issue 70: what else was typed keeps the form dirty', (
      tester,
    ) async {
      final state = await pumpCreate(tester);
      await enterField(tester, UserFormFields.firstNameId, 'Robin');
      await typeOwnPassword(tester);

      await tapCheckbox(tester, _useDefault);

      expect(state.isDirty, isTrue);
      expect(heldValue(state, UserFormFields.firstNameId), 'Robin');
    });
  });
}
