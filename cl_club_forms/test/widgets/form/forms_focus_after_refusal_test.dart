// Issue 93: after a refused save every form of cl_club_forms puts the focus
// where the member has to act, whichever order its host calls `showErrors`
// and turns it on again. The check itself is the harness's
// `expectFocusAfterRefusal`.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/form_cases.dart';
import '../../support/form_harness.dart';

void main() {
  group('Issue 93: after a refused save the focus goes to the first '
      'refused field', () {
    for (final order in RefusalOrder.values) {
      for (final c in formCases) {
        testWidgets('Issue 93: ${c.name}, ${order.name}: a refused field '
            'takes the focus or is scrolled into view, and a refusal that '
            'names none gives the cursor back', (tester) async {
          final focused = await expectFocusAfterRefusal(
            tester,
            c.build,
            order: order,
          );
          if (c.typed) expect(focused, greaterThan(0), reason: 'focused');
        });
      }

      testWidgets('Issue 93: ProgrammeEndDateForm, ${order.name}: a refused '
          'reason takes the cursor and a refused date does not', (
        tester,
      ) async {
        final key = GlobalKey<ProgrammeEndDateFormState>();
        final focused = await expectFocusAfterRefusal(
          tester,
          ({required enabled}) => ProgrammeEndDateForm(
            key: key,
            enabled: enabled,
            initialDay: DateTime(2030, 5, 14),
            reasonRequired: true,
            resultOf: (day) => 'Last session: day ${day.day}.',
          ),
          order: order,
        );
        expect(key.currentState!.formKey.currentState!.fields, hasLength(2));
        expect(focused, 1);
      });
    }

    testWidgets('Issue 93: a refusal that names no field, when the input '
        'that had the cursor is gone, gives the cursor to the first field '
        'that can take it', (tester) async {
      final key = GlobalKey<LoginFormState>();
      final enabled = ValueNotifier<bool>(true);
      addTearDown(enabled.dispose);
      await pumpForm(
        tester,
        ValueListenableBuilder<bool>(
          valueListenable: enabled,
          builder: (context, on, _) => LoginForm(key: key, enabled: on),
        ),
      );
      final state = key.currentState!;
      await tester.showKeyboard(
        find.descendant(
          of: fieldWithId(LoginFormFields.passwordId),
          matching: find.byType(EditableText),
        ),
      );
      await tester.pumpAndSettle();
      enabled.value = false;
      await tester.pumpAndSettle();
      // The control that had the cursor is no longer there to take it.
      state.focusTakenAway = FocusNode();
      addTearDown(state.focusTakenAway!.dispose);

      state.showErrors(formError: 'Wrong username or password.');
      enabled.value = true;
      await tester.pumpAndSettle();

      final fields = state.formKey.currentState!.fields;
      expect(fields[LoginFormFields.usernameId]!.focusNode.hasFocus, isTrue);
    });

    testWidgets('Issue 93: a form turned on again without a refusal gives '
        'the cursor back, and one the member left alone takes none', (
      tester,
    ) async {
      final enabled = ValueNotifier<bool>(true);
      addTearDown(enabled.dispose);
      await pumpForm(
        tester,
        ValueListenableBuilder<bool>(
          valueListenable: enabled,
          builder: (context, on, _) => ForgotPasswordForm(enabled: on),
        ),
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      enabled.value = false;
      await tester.pumpAndSettle();
      enabled.value = true;
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, isA<FocusScopeNode>());

      await tester.showKeyboard(find.byType(EditableText).first);
      await tester.pumpAndSettle();
      final cursor = tester
          .widget<EditableText>(find.byType(EditableText).first)
          .focusNode;
      enabled.value = false;
      await tester.pumpAndSettle();
      expect(cursor.hasFocus, isFalse);
      enabled.value = true;
      await tester.pumpAndSettle();
      expect(cursor.hasFocus, isTrue);
    });
  });
}
