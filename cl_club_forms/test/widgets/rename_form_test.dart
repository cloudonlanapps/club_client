import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/admin_forms_checks.dart';
import '../support/form_harness.dart';

// Against the list of club_client#61: RenameForm has one field, so there is
// no rule across fields; no parameter hides or locks it; it draws no heading
// and no button.
typedef _F = RenameFormFields;

Widget _wrap(Widget child) => ShadApp(home: Scaffold(body: child));

void main() {
  testWidgets('respects the initial value and returns it trimmed', (
    tester,
  ) async {
    final key = GlobalKey<RenameFormState>();
    await tester.pumpWidget(
      _wrap(
        RenameForm(key: key, initialValue: 'U12 Boys', label: 'Group Name'),
      ),
    );
    await tester.pumpAndSettle();

    // Field shows the initial value (not blank).
    expect(find.text('U12 Boys'), findsOneWidget);
    expect(key.currentState!.validate(), {
      RenameFormFields.valueId: 'U12 Boys',
    });
  });

  testWidgets('default validator rejects empty input', (tester) async {
    final key = GlobalKey<RenameFormState>();
    await tester.pumpWidget(
      _wrap(RenameForm(key: key, initialValue: '', label: 'Group Name')),
    );
    await tester.pumpAndSettle();

    expect(key.currentState!.validate(), isNull);
    await tester.pumpAndSettle();
    expect(find.text('Group Name is required'), findsOneWidget);
  });

  testWidgets('honors a custom validator', (tester) async {
    final key = GlobalKey<RenameFormState>();
    await tester.pumpWidget(
      _wrap(
        RenameForm(
          key: key,
          initialValue: 'a',
          label: 'Venue name',
          validator: (v) =>
              v.trim().length < 2 ? 'At least 2 characters' : null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(key.currentState!.validate(), isNull);
    await tester.pumpAndSettle();
    expect(find.text('At least 2 characters'), findsOneWidget);
  });

  testWidgets('Issue 173: RenameForm shows an error the host sets', (
    tester,
  ) async {
    final key = GlobalKey<RenameFormState>();
    await tester.pumpWidget(
      _wrap(RenameForm(key: key, initialValue: 'Skating', label: 'Name')),
    );
    await tester.pumpAndSettle();
    key.currentState!.showErrors(
      fieldErrors: {RenameFormFields.valueId: 'Name taken.'},
    );
    await tester.pump();
    expect(find.text('Name taken.'), findsOneWidget);
  });

  group('Issue 61: RenameForm', () {
    Future<RenameFormState> pump(
      WidgetTester tester, {
      String initialValue = 'Juniors',
      String label = 'Group Name',
      String? placeholder,
      String? Function(String)? validator,
      VoidCallback? onSubmitted,
      bool enabled = true,
    }) async {
      final key = GlobalKey<RenameFormState>();
      await pumpForm(
        tester,
        RenameForm(
          key: key,
          initialValue: initialValue,
          label: label,
          placeholder: placeholder,
          validator: validator,
          onSubmitted: onSubmitted,
          enabled: enabled,
        ),
      );
      return key.currentState!;
    }

    Future<Map<String, dynamic>?> validate(
      WidgetTester tester,
      RenameFormState state,
    ) async {
      final values = state.validate();
      await tester.pumpAndSettle();
      return values;
    }

    testWidgets('Issue 61: it shows its one field as a required row under '
        'the label it is given', (tester) async {
      await pump(tester, label: 'Venue name');

      expect(rowLabels(tester), ['Venue name *']);
      expectLabelsAreRows(tester);
      expect(formOf(tester).fields.keys, [_F.valueId]);
    });

    testWidgets('Issue 61: empty, it shows the placeholder it is given', (
      tester,
    ) async {
      await pump(tester, initialValue: '', placeholder: 'e.g., U12 Boys');

      expect(
        find.descendant(
          of: fieldWithId(_F.valueId),
          matching: find.text('e.g., U12 Boys'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Issue 61: it draws no heading and no button', (tester) async {
      await pump(tester);

      expectNoHostChrome(tester);
      expect(find.byType(ShadButton), findsNothing);
    });

    testWidgets('Issue 61: a text of spaces only is refused on the field, '
        'the message naming the label', (tester) async {
      final state = await pump(tester, label: 'Venue name');
      await enterField(tester, _F.valueId, '   ');

      expect(await validate(tester, state), isNull);
      expectFieldError(_F.valueId, 'Venue name is required');
    });

    testWidgets('Issue 61: by default one character is enough', (
      tester,
    ) async {
      final state = await pump(tester);
      await enterField(tester, _F.valueId, 'A');

      expect(await validate(tester, state), {_F.valueId: 'A'});
    });

    testWidgets('Issue 61: a validator given replaces the default one, and '
        'its message shows on the field', (tester) async {
      final state = await pump(
        tester,
        validator: (value) => value.isEmpty ? null : 'Leave it empty',
      );

      expect(await validate(tester, state), isNull);
      expectFieldError(_F.valueId, 'Leave it empty');

      await enterField(tester, _F.valueId, '');
      expect(await validate(tester, state), {_F.valueId: ''});
      expect(find.text('Group Name is required'), findsNothing);
    });

    testWidgets('Issue 61: validate returns exactly the one text, trimmed', (
      tester,
    ) async {
      final state = await pump(tester);
      await enterField(tester, _F.valueId, '  Seniors ');

      final values = await validate(tester, state);

      expect(values, {_F.valueId: 'Seniors'});
      expect(values![_F.valueId], isA<String>());
    });

    testWidgets('Issue 61: typing dirties it, and typing the old text back '
        'cleans it', (tester) async {
      final state = await pump(tester);
      expect(state.isDirty, isFalse);

      await enterField(tester, _F.valueId, 'Seniors');
      expect(state.isDirty, isTrue);

      await enterField(tester, _F.valueId, 'Juniors');
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: Enter in the field is handed to the host', (
      tester,
    ) async {
      var submitted = 0;
      await pump(tester, onSubmitted: () => submitted++);

      await tester.showKeyboard(find.byType(EditableText));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(submitted, 1);
    });

    testWidgets('Issue 61: showErrors puts a message on the field and one '
        'inline', (tester) async {
      final state = await pump(tester);

      await expectShowsServerErrors(tester, state, _F.valueId);
    });

    testWidgets('Issue 61: after a name the server refused, a new one '
        'validates and comes back', (tester) async {
      final state = await pump(tester);
      state.showErrors(fieldErrors: {_F.valueId: 'Name taken.'});
      await tester.pumpAndSettle();
      expectFieldError(_F.valueId, 'Name taken.');

      await enterField(tester, _F.valueId, 'Seniors');

      expect(await validate(tester, state), {_F.valueId: 'Seniors'});
      expect(find.text('Name taken.'), findsNothing);
    });

    testWidgets('Issue 61: with enabled false the field does not respond', (
      tester,
    ) async {
      await pump(tester, enabled: false);

      await expectNoFieldResponds(tester);
    });

    testWidgets('Issue 61: it fits a phone', (tester) async {
      await expectFitsPhone(
        tester,
        const RenameForm(
          initialValue: 'A rather long name for a group of young players',
          label: 'Group Name',
        ),
      );
    });
  });
}
