// Issue 97: in every form of cl_club_forms the form-level message goes on
// the next edit. The check itself is the harness's
// `expectFormErrorGoesOnEdit`.
import 'dart:io';

import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/form_cases.dart';
import '../../support/form_harness.dart';

void main() {
  group('Issue 97: a form-level message goes on the next edit', () {
    for (final c in formCases) {
      testWidgets('Issue 97: ${c.name}: the form-level message goes on the '
          'next edit of the form', (tester) async {
        final edited = await expectFormErrorGoesOnEdit(tester, c.build);
        expect(edited, isTrue, reason: 'no field to edit');
      });
    }

    testWidgets('Issue 97: a second message, after the first went on an '
        'edit, goes on the next edit too, and a message of validate() does '
        'as well', (tester) async {
      final key = GlobalKey<ChangePasswordFormState>();
      await pumpForm(tester, ChangePasswordForm(key: key));
      final state = key.currentState!;

      for (final typed in ['one', 'two']) {
        state.showErrors(formError: 'Could not save.');
        await tester.pumpAndSettle();
        expect(find.text('Could not save.'), findsOneWidget);
        await enterField(tester, ChangePasswordFormFields.currentId, typed);
        expect(find.text('Could not save.'), findsNothing, reason: typed);
      }

      await enterField(tester, ChangePasswordFormFields.nextId, 'new-pass-1');
      await enterField(tester, ChangePasswordFormFields.confirmId, 'other-1');
      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      final shown = state.formError;
      expect(shown, isNotNull);
      expect(find.text(shown!), findsOneWidget);
      await enterField(
        tester,
        ChangePasswordFormFields.confirmId,
        'new-pass-1',
      );
      expect(state.formError, isNull);
    });

    test('Issue 97: no form clears its form-level message from its own '
        'onChanged', () {
      final own = [
        for (final file in Directory('lib/src/widgets').listSync(
          recursive: true,
        ))
          if (file is File &&
              file.path.endsWith('.dart') &&
              RegExp(
                r'onChanged:\s*\(_?\)\s*=>\s*setFormError\(null\)',
              ).hasMatch(file.readAsStringSync()))
            file.path,
      ];
      expect(own, isEmpty);
    });
  });
}
