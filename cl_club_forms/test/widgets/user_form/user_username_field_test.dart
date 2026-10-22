// UserUsernameField is one labelled input of the forms that create an
// account: its format rule, its typing filter and its hint. A username the
// server finds taken is the host's refusal (`showErrors`), tested with the
// forms.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/user_form/user_username_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/account_user_form_harness.dart';
import '../../support/form_harness.dart';

const String _id = UserFormFields.usernameId;
const _hint = 'Lowercase letters, digits, and _ only';

class _Host {
  final formKey = GlobalKey<ShadFormState>();

  Widget build({bool enabled = true}) => ShadForm(
    key: formKey,
    child: UserUsernameField(enabled: enabled),
  );

  ShadFormState get form => formKey.currentState!;
}

Future<_Host> _pump(WidgetTester tester) async {
  final host = _Host();
  await pumpForm(tester, host.build());
  return host;
}

EditableText _input(WidgetTester tester) => tester.widget<EditableText>(
  find.descendant(of: fieldWithId(_id), matching: find.byType(EditableText)),
);

void main() {
  group('Issue 161: UserUsernameField', () {
    testWidgets('Issue 161: it shows its label and hint, and no '
        'availability check', (tester) async {
      await _pump(tester);
      await enterField(tester, _id, 'robin');

      expect(find.text('Username *'), findsOneWidget);
      expect(find.text(_hint), findsOneWidget);
      expect(find.text('Check availability'), findsNothing);
      expect(find.byType(ShadButton), findsNothing);
    });

    testWidgets('Issue 161: it keeps lowercase letters, digits and _ and '
        'drops everything else as typed', (tester) async {
      final host = await _pump(tester);

      await enterField(tester, _id, 'Ro-Bin 9_x!');

      expect(_input(tester).controller.text, 'oin9_x');
      expect(host.form.value[_id], 'oin9_x');
    });

    testWidgets('Issue 161: a badly formed username is refused on the field', (
      tester,
    ) async {
      final host = await _pump(tester);

      expect(host.form.saveAndValidate(), isFalse);
      await tester.pumpAndSettle();
      expectMessageOn(_id, 'Username is required');

      await enterField(tester, _id, 'ab');
      expect(host.form.saveAndValidate(), isFalse);
      await tester.pumpAndSettle();
      expectMessageOn(_id, 'At least 3 characters');

      await enterField(tester, _id, 'abc');
      expect(host.form.saveAndValidate(), isTrue);
    });

    testWidgets('Issue 161: with enabled off the input does not respond', (
      tester,
    ) async {
      final host = _Host();
      await pumpForm(tester, host.build(enabled: false));

      expect(
        tester.widget<ShadInputFormField>(fieldWithId(_id)).enabled,
        isFalse,
      );
    });

    testWidgets('Issue 161: it fits a phone', (tester) async {
      await expectFitsPhone(tester, _Host().build());
      await enterField(tester, _id, 'a_rather_long_username_for_a_phone');

      expect(tester.takeException(), isNull);
    });
  });
}
