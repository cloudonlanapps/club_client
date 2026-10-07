import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/admin_forms_checks.dart';
import '../../support/form_harness.dart';
import 'club_identity_form_pump.dart';

// Against the list of club_client#61: ClubLanguageForm has one field, so
// there is no rule across fields; the field is not marked required, though
// an empty code is refused; `languages` hides or locks nothing; the form
// draws no heading and no button.

typedef _F = ClubLanguageFormFields;

Future<GlobalKey<ClubLanguageFormState>> _pump(
  WidgetTester tester, {
  List<String> languages = const ['mr'],
  VoidCallback? onSubmitted,
}) async {
  final key = GlobalKey<ClubLanguageFormState>();
  await pumpClubIdentityForm(
    tester,
    ClubLanguageForm(
      key: key,
      languages: languages,
      onSubmitted: onSubmitted,
    ),
  );
  return key;
}

Finder get _input => find.descendant(
  of: find.byKey(_F.languageCodeKey),
  matching: find.byType(EditableText),
);

Future<void> _enter(WidgetTester tester, String text) async {
  await tester.enterText(_input, text);
  await tester.pump();
}

void main() {
  group('Issue 58: ClubLanguageForm', () {
    testWidgets('Issue 58: ClubLanguageForm has one labelled field, no card '
        'and no button', (tester) async {
      await _pump(tester);

      expect(find.byType(EditableText), findsOneWidget);
      expect(find.text(_F.languageCodeLabel), findsOneWidget);
      expect(find.text(_F.languageCodePlaceholder), findsOneWidget);
      expect(
        find.byKey(const ValueKey('clubIdentity.addLanguage')),
        findsOneWidget,
      );
      expectNoCardAndNoButton();
    });

    testWidgets('Issue 58: ClubLanguageForm accepts a valid code and '
        'returns it trimmed', (tester) async {
      final key = await _pump(tester);
      expect(key.currentState!.isDirty, isFalse);

      await _enter(tester, ' hi ');

      expect(key.currentState!.isDirty, isTrue);
      expect(key.currentState!.validate(), {_F.languageCodeId: 'hi'});
    });

    testWidgets('Issue 58: ClubLanguageForm refuses an invalid code, and an '
        'empty one, on the field', (tester) async {
      final key = await _pump(tester);

      expect(key.currentState!.validate(), isNull);
      await tester.pump();
      expect(find.textContaining('two- or three-letter'), findsOneWidget);

      await _enter(tester, 'Marathi');
      expect(key.currentState!.validate(), isNull);
      await tester.pump();
      expect(find.textContaining('two- or three-letter'), findsOneWidget);
    });

    testWidgets('Issue 58: ClubLanguageForm refuses a code that is already '
        'listed', (tester) async {
      final key = await _pump(tester);

      await _enter(tester, 'mr');

      expect(key.currentState!.validate(), isNull);
      await tester.pump();
      expect(find.text('mr is already offered'), findsOneWidget);
    });

    testWidgets('Issue 58: ClubLanguageForm reset empties the field and its '
        'message', (tester) async {
      final key = await _pump(tester);

      await _enter(tester, 'mr');
      expect(key.currentState!.validate(), isNull);
      await tester.pump();

      key.currentState!.reset();
      await tester.pump();

      expect(find.text('mr'), findsNothing);
      expect(find.text('mr is already offered'), findsNothing);
      expect(key.currentState!.isDirty, isFalse);
    });

    testWidgets('Issue 58: ClubLanguageForm hands Enter to the host', (
      tester,
    ) async {
      var submitted = 0;
      await _pump(tester, onSubmitted: () => submitted++);

      await _enter(tester, 'hi');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(submitted, 1);
    });
  });

  group('Issue 61: ClubLanguageForm', () {
    const shapeMessage =
        'Use a two- or three-letter language code in lowercase, '
        'e.g. mr or hi';

    Future<Map<String, dynamic>?> validate(
      WidgetTester tester,
      GlobalKey<ClubLanguageFormState> key,
    ) async {
      final values = key.currentState!.validate();
      await tester.pumpAndSettle();
      return values;
    }

    testWidgets('Issue 61: its one field is a labelled row, registered '
        'under the language code id', (tester) async {
      await _pump(tester);

      expect(rowLabels(tester), [_F.languageCodeLabel]);
      expectLabelsAreRows(tester);
      expectNoHostChrome(tester);
      expect(formOf(tester).fields.keys, [_F.languageCodeId]);
    });

    testWidgets('Issue 61: an empty code is refused with its message on '
        'the field', (tester) async {
      final key = await _pump(tester);

      expect(await validate(tester, key), isNull);
      expectFieldError(_F.languageCodeId, shapeMessage);
    });

    for (final code in ['m', 'MR', 'mara', 'm1', 'pt-BR']) {
      testWidgets('Issue 61: "$code" is refused on the field as no '
          'language code', (tester) async {
        final key = await _pump(tester);
        await _enter(tester, code);

        expect(await validate(tester, key), isNull);
        expectFieldError(_F.languageCodeId, shapeMessage);
      });
    }

    testWidgets('Issue 61: a two-letter and a three-letter code are both '
        'accepted', (tester) async {
      final key = await _pump(tester);

      for (final code in ['hi', 'kok']) {
        await _enter(tester, code);
        expect(await validate(tester, key), {_F.languageCodeId: code});
        expect(find.text(shapeMessage), findsNothing);
      }
    });

    testWidgets('Issue 61: a listed code typed with spaces around it is '
        'still refused as listed, on the field', (tester) async {
      final key = await _pump(tester, languages: const ['mr', 'hi']);
      await _enter(tester, ' hi ');

      expect(await validate(tester, key), isNull);
      expectFieldError(_F.languageCodeId, 'hi is already offered');
    });

    testWidgets('Issue 61: with no language listed any well-formed code '
        'passes', (tester) async {
      final key = await _pump(tester, languages: const []);
      await _enter(tester, 'mr');

      final values = await validate(tester, key);
      expect(values, {_F.languageCodeId: 'mr'});
      expect(values![_F.languageCodeId], isA<String>());
    });

    testWidgets('Issue 61: typing dirties it, and emptying the field '
        'cleans it', (tester) async {
      final key = await _pump(tester);
      expect(key.currentState!.isDirty, isFalse);

      await _enter(tester, 'hi');
      expect(key.currentState!.isDirty, isTrue);

      await _enter(tester, '');
      expect(key.currentState!.isDirty, isFalse);
    });

    testWidgets('Issue 61: showErrors puts a message on the field and one '
        'inline', (tester) async {
      final key = await _pump(tester);

      await expectShowsServerErrors(
        tester,
        key.currentState!,
        _F.languageCodeId,
      );
    });

    testWidgets('Issue 61: after a refusal it validates and returns its '
        'code again, and reset clears a refusal too', (tester) async {
      final key = await _pump(tester);
      await _enter(tester, 'hi');

      expect(
        await expectSavesAfterRefusal(
          tester,
          key.currentState!,
          _F.languageCodeId,
        ),
        {_F.languageCodeId: 'hi'},
      );

      key.currentState!.showErrors(formError: 'Could not add.');
      await tester.pumpAndSettle();
      expect(find.text('Could not add.'), findsOneWidget);
      key.currentState!.reset();
      await tester.pumpAndSettle();
      expect(find.text('Could not add.'), findsNothing);
    });

    testWidgets('Issue 61: with enabled false the field does not respond', (
      tester,
    ) async {
      await pumpForm(
        tester,
        const ClubLanguageForm(languages: ['mr'], enabled: false),
      );

      await expectNoFieldResponds(tester);
    });

    testWidgets('Issue 61: it fits a phone', (tester) async {
      await expectFitsPhone(tester, const ClubLanguageForm(languages: ['mr']));
    });
  });
}
