import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/club_identity_form/translated_text_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/admin_forms_checks.dart';
import '../../support/form_harness.dart';
import 'club_identity_form_pump.dart';

// Against the list of club_client#61: no field of ClubDetailsForm is
// required (every part of the club's identity is optional); one field has a
// validator (the inquiry email) and there is one rule across fields (a
// translation needs its default text); `languages` adds inputs but hides or
// locks none; the form draws no heading and no button.

typedef _F = ClubDetailsFormFields;

const _initial = <String, dynamic>{
  _F.nameId: 'Example Club',
  _F.taglineId: FormTranslatedText('Skate with us', {'mr': 'Namaskar'}),
};

Future<GlobalKey<ClubDetailsFormState>> _pump(
  WidgetTester tester, {
  Map<String, dynamic> initialValues = _initial,
  List<String> languages = const ['mr'],
}) async {
  final key = GlobalKey<ClubDetailsFormState>();
  await pumpClubIdentityForm(
    tester,
    ClubDetailsForm(
      key: key,
      initialValues: initialValues,
      languages: languages,
    ),
  );
  return key;
}

void main() {
  group('Issue 20: ClubIdentityForm', () {
    testWidgets('Issue 20: shows the stored values and returns them, '
        'translations included', (tester) async {
      final key = await _pump(tester);

      expect(find.text('Example Club'), findsOneWidget);
      expect(find.text('Skate with us'), findsOneWidget);
      expect(find.text('Namaskar'), findsOneWidget);

      expect(key.currentState!.validate(), {
        _F.nameId: 'Example Club',
        _F.shortNameId: '',
        _F.inquiryEmailId: '',
        _F.taglineId: const FormTranslatedText('Skate with us', {
          'mr': 'Namaskar',
        }),
      });
    });

    testWidgets('Issue 20: values come back trimmed, and an emptied '
        'translation is dropped', (tester) async {
      final key = await _pump(tester);

      await enterClubIdentityText(tester, _F.shortNameId, '  EXC ');
      await enterClubIdentityText(
        tester,
        translationId(_F.taglineId, 'mr'),
        '   ',
      );

      final values = key.currentState!.validate()!;
      expect(values[_F.shortNameId], 'EXC');
      expect(values[_F.taglineId], const FormTranslatedText('Skate with us'));
    });

    testWidgets('Issue 20: a translation without a default text is refused '
        'with a form-level message', (tester) async {
      final key = await _pump(tester);

      await enterClubIdentityText(tester, _F.taglineId, '');

      expect(key.currentState!.validate(), isNull);
      await tester.pump();
      expect(
        find.text('Tagline has a translation but no default text.'),
        findsOneWidget,
      );
    });
  });

  group('Issue 58: ClubDetailsForm', () {
    testWidgets('Issue 58: ClubDetailsForm has its four fields, no card and '
        'no button', (tester) async {
      await _pump(tester, languages: const []);

      for (final id in _F.labels.keys) {
        expect(clubIdentityInput(id), findsOneWidget, reason: id);
      }
      for (final label in _F.labels.values) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.byType(EditableText), findsNWidgets(_F.labels.length));
      expect(find.text(_F.inquiryEmailHelp), findsOneWidget);
      expectNoCardAndNoButton();
    });

    testWidgets('Issue 58: ClubDetailsForm refuses a bad inquiry email', (
      tester,
    ) async {
      final key = await _pump(tester);

      await enterClubIdentityText(tester, _F.inquiryEmailId, 'desk-at-club');

      expect(key.currentState!.validate(), isNull);
      await tester.pump();
      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('Issue 58: ClubDetailsForm offers the tagline in each '
        'language the host passes in, and in no other', (tester) async {
      final key = await _pump(tester, languages: const ['hi']);

      expect(
        clubIdentityInput(translationId(_F.taglineId, 'hi')),
        findsOneWidget,
      );
      expect(
        clubIdentityInput(translationId(_F.taglineId, 'mr')),
        findsNothing,
      );

      await enterClubIdentityText(
        tester,
        translationId(_F.taglineId, 'hi'),
        'Namaste',
      );

      // The stored translation the form has no input for is kept.
      expect(
        key.currentState!.validate()![_F.taglineId],
        const FormTranslatedText('Skate with us', {
          'mr': 'Namaskar',
          'hi': 'Namaste',
        }),
      );
    });

    testWidgets('Issue 58: ClubDetailsForm clears the translation message '
        'on the next edit, and follows the edits with isDirty', (tester) async {
      final key = await _pump(tester);
      expect(key.currentState!.isDirty, isFalse);

      await enterClubIdentityText(tester, _F.taglineId, '');
      expect(key.currentState!.isDirty, isTrue);
      expect(key.currentState!.validate(), isNull);
      await tester.pump();
      expect(find.textContaining('no default text'), findsOneWidget);

      await enterClubIdentityText(tester, _F.taglineId, 'Skate with us');
      await tester.pump();
      expect(find.textContaining('no default text'), findsNothing);
      expect(key.currentState!.isDirty, isFalse);
    });
  });

  group('Issue 61: ClubDetailsForm', () {
    Future<Map<String, dynamic>?> validate(
      WidgetTester tester,
      GlobalKey<ClubDetailsFormState> key,
    ) async {
      final values = key.currentState!.validate();
      await tester.pumpAndSettle();
      return values;
    }

    testWidgets('Issue 61: without languages it shows its four fields as '
        'labelled rows, none required', (tester) async {
      await _pump(tester, languages: const []);

      expect(rowLabels(tester), [
        'Name',
        'Short name',
        'Tagline',
        'Inquiry email',
      ]);
      expectLabelsAreRows(tester);
      expect(find.text(TranslatedTextInputs.defaultHelp), findsNothing);
    });

    testWidgets('Issue 61: with two languages the tagline gets a row per '
        'language, after its default', (tester) async {
      await _pump(tester, languages: const ['mr', 'hi']);

      expect(rowLabels(tester), [
        'Name',
        'Short name',
        'Tagline',
        'Tagline (mr)',
        'Tagline (hi)',
        'Inquiry email',
      ]);
      expectLabelsAreRows(tester);
      expect(find.text(TranslatedTextInputs.defaultHelp), findsOneWidget);
    });

    testWidgets('Issue 61: missing values read empty, other keys are '
        'ignored, and an empty form is valid', (tester) async {
      final key = await _pump(
        tester,
        initialValues: const {'postalCode': '000000'},
      );

      expect(await validate(tester, key), {
        _F.nameId: '',
        _F.shortNameId: '',
        _F.inquiryEmailId: '',
        _F.taglineId: const FormTranslatedText(''),
      });
    });

    testWidgets('Issue 61: a well-formed inquiry email is accepted and '
        'comes back trimmed', (tester) async {
      final key = await _pump(tester);
      await enterClubIdentityText(
        tester,
        _F.inquiryEmailId,
        ' desk@club.example ',
      );

      expect(
        (await validate(tester, key))![_F.inquiryEmailId],
        'desk@club.example',
      );
      expect(find.text('Enter a valid email address'), findsNothing);
    });

    testWidgets('Issue 61: the refused inquiry email shows its message on '
        'that field', (tester) async {
      final key = await _pump(tester);
      await enterClubIdentityText(tester, _F.inquiryEmailId, 'desk@club');

      expect(await validate(tester, key), isNull);
      expectFieldError(_F.inquiryEmailId, 'Enter a valid email address');
    });

    testWidgets('Issue 61: translations in two languages come back '
        'together, typed and trimmed', (tester) async {
      final key = await _pump(tester, languages: const ['mr', 'hi']);
      await enterClubIdentityText(
        tester,
        translationId(_F.taglineId, 'hi'),
        ' Namaste ',
      );

      final values = await validate(tester, key);

      expect(
        values![_F.taglineId],
        const FormTranslatedText('Skate with us', {
          'mr': 'Namaskar',
          'hi': 'Namaste',
        }),
      );
      expect(values[_F.taglineId], isA<FormTranslatedText>());
      expect(values[_F.nameId], isA<String>());
    });

    testWidgets('Issue 61: translations in two languages without a default '
        'are refused until the default is typed or both are emptied', (
      tester,
    ) async {
      const message = 'Tagline has a translation but no default text.';
      final key = await _pump(
        tester,
        initialValues: const {},
        languages: const ['mr', 'hi'],
      );
      await enterClubIdentityText(
        tester,
        translationId(_F.taglineId, 'mr'),
        'Namaskar',
      );
      await enterClubIdentityText(
        tester,
        translationId(_F.taglineId, 'hi'),
        'Namaste',
      );
      expect(await validate(tester, key), isNull);
      expect(find.text(message), findsOneWidget);

      await enterClubIdentityText(
        tester,
        translationId(_F.taglineId, 'mr'),
        '',
      );
      expect(await validate(tester, key), isNull);
      expect(find.text(message), findsOneWidget);

      await enterClubIdentityText(
        tester,
        translationId(_F.taglineId, 'hi'),
        '',
      );
      expect(await validate(tester, key), isNotNull);
      expect(find.text(message), findsNothing);
    });

    testWidgets('Issue 61: a default of spaces only is no default', (
      tester,
    ) async {
      final key = await _pump(tester);
      await enterClubIdentityText(tester, _F.taglineId, '   ');

      expect(await validate(tester, key), isNull);
      expect(
        find.text('Tagline has a translation but no default text.'),
        findsOneWidget,
      );
    });

    testWidgets('Issue 61: a translation typed dirties it, and typing the '
        'old text back cleans it', (tester) async {
      final key = await _pump(tester);
      final id = translationId(_F.taglineId, 'mr');

      await enterClubIdentityText(tester, id, 'Namaste');
      expect(key.currentState!.isDirty, isTrue);

      await enterClubIdentityText(tester, id, 'Namaskar');
      expect(key.currentState!.isDirty, isFalse);
    });

    testWidgets('Issue 61: showErrors puts a message on a field and one '
        'inline', (tester) async {
      final key = await _pump(tester);

      await expectShowsServerErrors(tester, key.currentState!, _F.nameId);
    });

    testWidgets('Issue 61: a refusal about a translation shows on that '
        'translation, and the form saves again afterwards', (tester) async {
      final key = await _pump(tester);

      final values = await expectSavesAfterRefusal(
        tester,
        key.currentState!,
        translationId(_F.taglineId, 'mr'),
      );
      expect(values[_F.nameId], 'Example Club');
    });

    testWidgets('Issue 61: an edit takes the inline message of the server '
        'away', (tester) async {
      final key = await _pump(tester);
      key.currentState!.showErrors(formError: 'Could not save.');
      await tester.pumpAndSettle();
      expect(find.text('Could not save.'), findsOneWidget);

      await enterClubIdentityText(tester, _F.shortNameId, 'EXC');
      await tester.pumpAndSettle();
      expect(find.text('Could not save.'), findsNothing);
    });

    testWidgets('Issue 61: with enabled false no field responds, '
        'translations included', (tester) async {
      await pumpForm(
        tester,
        const ClubDetailsForm(
          initialValues: _initial,
          languages: ['mr', 'hi'],
          enabled: false,
        ),
      );

      expect(formOf(tester).fields, hasLength(6));
      await expectNoFieldResponds(tester);
    });

    testWidgets('Issue 61: it fits a phone with two languages', (tester) async {
      await expectFitsPhone(
        tester,
        const ClubDetailsForm(
          initialValues: _initial,
          languages: ['mr', 'hi'],
        ),
      );
    });
  });
}
