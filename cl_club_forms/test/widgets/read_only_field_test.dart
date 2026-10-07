// ReadOnlyField is a row, not a field: it has no value of its own, no
// validator, no enabled state and nothing to type, so of the list of
// club_client#61 only the label, the narrow width and the absence of chrome
// apply.
import 'package:cl_club_forms/src/widgets/read_only_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/admin_forms_checks.dart';
import '../support/form_harness.dart';

void main() {
  group('Issue 61: ReadOnlyField', () {
    testWidgets('Issue 61: it shows its value under its label, as a row '
        'that is not required', (tester) async {
      await pumpForm(
        tester,
        const ReadOnlyField(label: 'Username', value: 'asha'),
      );

      expect(rowLabels(tester), ['Username']);
      expect(find.text('asha'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('asha')).dy,
        greaterThan(tester.getBottomLeft(find.text('Username')).dy),
      );
    });

    testWidgets('Issue 61: it offers nothing to edit and no button', (
      tester,
    ) async {
      await pumpForm(
        tester,
        const ReadOnlyField(label: 'Username', value: 'asha'),
      );

      expect(find.byType(EditableText), findsNothing);
      expectNoHostChrome(tester);
      await tester.tap(find.text('asha'));
      await tester.pumpAndSettle();
      expect(tester.testTextInput.hasAnyClients, isFalse);
    });

    testWidgets('Issue 61: inside a form it adds no field and no value', (
      tester,
    ) async {
      final key = GlobalKey<ShadFormState>();
      await pumpForm(
        tester,
        ClusterHost(
          formKey: key,
          builder: (_) => const ReadOnlyField(label: 'Username', value: 'asha'),
        ),
      );

      expect(key.currentState!.fields, isEmpty);
      expect(key.currentState!.value, isEmpty);
      expect(key.currentState!.saveAndValidate(), isTrue);
    });

    testWidgets('Issue 61: its box spans the row', (tester) async {
      await pumpForm(
        tester,
        const ReadOnlyField(label: 'Username', value: 'asha'),
      );

      final box = tester.getSize(
        find.ancestor(of: find.text('asha'), matching: find.byType(Container)),
      );
      // The surface, less the harness's 16 px padding on each side.
      expect(box.width, kFormSurface.width - 32);
    });

    testWidgets('Issue 61: a long value wraps at phone width', (tester) async {
      const value =
          'a-very-long-username-that-does-not-fit-on-one-line '
          'and goes on for a while longer than the row is wide';
      await expectFitsPhone(
        tester,
        const ReadOnlyField(label: 'Username', value: value),
      );

      expect(
        tester.getSize(find.text(value)).height,
        greaterThan(tester.getSize(find.text('Username')).height * 2),
      );
    });
  });
}
