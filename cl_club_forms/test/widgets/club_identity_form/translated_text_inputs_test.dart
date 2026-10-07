// TranslatedTextInputs and ClubIdentityTextInput, the two pieces the club
// identity section forms are built from, each mounted alone under a bare
// ShadForm. Neither holds a rule across fields (the forms apply
// ClubIdentityFormValues.missingDefaultError) or an `enabled` of its own:
// both follow the enclosing form's.
import 'package:cl_club_forms/src/widgets/club_identity_form/club_identity_text_input.dart';
import 'package:cl_club_forms/src/widgets/club_identity_form/translated_text_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/admin_forms_checks.dart';
import '../../support/form_harness.dart';

Future<ShadFormState> _pump(
  WidgetTester tester,
  Widget cluster, {
  Map<String, dynamic> initialValue = const {},
  bool enabled = true,
  Size size = kFormSurface,
}) async {
  final key = GlobalKey<ShadFormState>();
  await pumpForm(
    tester,
    ClusterHost(
      formKey: key,
      initialValue: initialValue,
      enabled: enabled,
      builder: (_) => cluster,
    ),
    size: size,
  );
  return key.currentState!;
}

EditableText _editable(WidgetTester tester, String id) =>
    tester.widget<EditableText>(
      find.descendant(of: fieldWithId(id), matching: find.byType(EditableText)),
    );

void main() {
  group('Issue 61: ClubIdentityTextInput', () {
    testWidgets('Issue 61: it is a labelled row, not required, keyed by its '
        'id and registered under it', (tester) async {
      final form = await _pump(
        tester,
        const ClubIdentityTextInput(
          id: 'name',
          label: 'Name',
          keyboardType: TextInputType.name,
        ),
      );

      expect(rowLabels(tester), ['Name']);
      expectLabelsAreRows(tester);
      expect(form.fields.keys, ['name']);
      expect(
        ClubIdentityTextInput.keyOf('name'),
        const ValueKey('clubIdentity.name'),
      );
      expect(
        tester.widget(find.byKey(ClubIdentityTextInput.keyOf('name'))),
        tester.widget(fieldWithId('name')),
      );
    });

    testWidgets(
      'Issue 61: it starts with the value the form holds for its id, and '
      'what is typed reaches the form',
      (tester) async {
        final form = await _pump(
          tester,
          const ClubIdentityTextInput(
            id: 'name',
            label: 'Name',
            keyboardType: TextInputType.name,
          ),
          initialValue: const {'name': 'Example Club'},
        );

        expect(_editable(tester, 'name').controller.text, 'Example Club');

        await enterField(tester, 'name', 'Other Club');
        expect(form.value, {'name': 'Other Club'});
      },
    );

    testWidgets('Issue 61: its help shows under the input when given', (
      tester,
    ) async {
      await _pump(
        tester,
        const ClubIdentityTextInput(
          id: 'email',
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
          description: 'Not shown publicly.',
        ),
      );

      final help = find.descendant(
        of: fieldWithId('email'),
        matching: find.text('Not shown publicly.'),
      );
      expect(help, findsOneWidget);
      expect(
        tester.getTopLeft(help).dy,
        greaterThan(tester.getBottomLeft(find.byType(EditableText)).dy),
      );
    });

    testWidgets('Issue 61: without a validator it takes any text; with one, '
        'the message shows on the field', (tester) async {
      final form = await _pump(
        tester,
        Column(
          children: [
            const ClubIdentityTextInput(
              id: 'free',
              label: 'Free',
              keyboardType: TextInputType.text,
            ),
            ClubIdentityTextInput(
              id: 'checked',
              label: 'Checked',
              keyboardType: TextInputType.text,
              validator: (value) => value == 'ok' ? null : 'Type ok',
            ),
          ],
        ),
      );
      await enterField(tester, 'free', '?!');
      await enterField(tester, 'checked', 'no');

      expect(form.saveAndValidate(), isFalse);
      await tester.pumpAndSettle();
      expectFieldError('checked', 'Type ok');

      await enterField(tester, 'checked', 'ok');
      expect(form.saveAndValidate(), isTrue);
      await tester.pumpAndSettle();
      expect(find.text('Type ok'), findsNothing);
    });

    testWidgets('Issue 61: it asks for the keyboard it is given, on one '
        'line; multiline asks for two to four lines', (tester) async {
      await _pump(
        tester,
        const Column(
          children: [
            ClubIdentityTextInput(
              id: 'phone',
              label: 'Phone',
              keyboardType: TextInputType.phone,
            ),
            ClubIdentityTextInput(
              id: 'message',
              label: 'Message',
              keyboardType: TextInputType.text,
              multiline: true,
            ),
          ],
        ),
      );

      final phone = _editable(tester, 'phone');
      expect(phone.keyboardType, TextInputType.phone);
      expect(phone.maxLines, 1);
      final message = _editable(tester, 'message');
      expect(message.keyboardType, TextInputType.multiline);
      expect(message.minLines, ClubIdentityTextInput.multilineMinLines);
      expect(message.maxLines, ClubIdentityTextInput.multilineMaxLines);
    });

    testWidgets('Issue 61: only a plain text keyboard corrects spelling', (
      tester,
    ) async {
      await _pump(
        tester,
        const Column(
          children: [
            ClubIdentityTextInput(
              id: 'tagline',
              label: 'Tagline',
              keyboardType: TextInputType.text,
            ),
            ClubIdentityTextInput(
              id: 'email',
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      );

      expect(_editable(tester, 'tagline').autocorrect, isTrue);
      expect(_editable(tester, 'email').autocorrect, isFalse);
    });

    testWidgets('Issue 61: it follows the enabled of the form around it', (
      tester,
    ) async {
      await _pump(
        tester,
        const ClubIdentityTextInput(
          id: 'name',
          label: 'Name',
          keyboardType: TextInputType.name,
        ),
        initialValue: const {'name': 'Example Club'},
        enabled: false,
      );

      await expectNoFieldResponds(tester);
    });
  });

  group('Issue 61: TranslatedTextInputs', () {
    const initial = <String, dynamic>{
      'tagline': 'Skate with us',
      'tagline@mr': 'Namaskar',
      'tagline@hi': '',
    };

    Widget inputs({
      List<String> languages = const ['mr', 'hi'],
      TextInputType keyboardType = TextInputType.text,
      bool multiline = false,
    }) => TranslatedTextInputs(
      id: 'tagline',
      label: 'Tagline',
      languages: languages,
      keyboardType: keyboardType,
      multiline: multiline,
    );

    test('Issue 61: the field id of a translation is the id, @ and the '
        'language', () {
      expect(
        TranslatedTextInputs.translationIdOf('tagline', 'mr'),
        'tagline@mr',
      );
      expect(TranslatedTextInputs.languageSeparator, '@');
    });

    testWidgets('Issue 61: without languages it is the default input alone, '
        'with no help', (tester) async {
      final form = await _pump(tester, inputs(languages: const []));

      expect(rowLabels(tester), ['Tagline']);
      expect(form.fields.keys, ['tagline']);
      expect(find.text(TranslatedTextInputs.defaultHelp), findsNothing);
    });

    testWidgets('Issue 61: with languages it adds one labelled input per '
        'language, in order, each its own form field', (tester) async {
      final form = await _pump(tester, inputs(), initialValue: initial);

      expect(rowLabels(tester), ['Tagline', 'Tagline (mr)', 'Tagline (hi)']);
      expectLabelsAreRows(tester);
      expect(form.fields.keys, ['tagline', 'tagline@mr', 'tagline@hi']);
      // `@` is not the form's nesting separator: the values stay flat.
      expect(form.value, initial);
    });

    testWidgets(
      'Issue 61: each input starts with the text the form holds for it',
      (
        tester,
      ) async {
        await _pump(tester, inputs(), initialValue: initial);

        expect(_editable(tester, 'tagline').controller.text, 'Skate with us');
        expect(_editable(tester, 'tagline@mr').controller.text, 'Namaskar');
        expect(_editable(tester, 'tagline@hi').controller.text, isEmpty);
      },
    );

    testWidgets('Issue 61: what is typed in one input changes that field '
        'alone', (tester) async {
      final form = await _pump(tester, inputs(), initialValue: initial);

      await enterField(tester, 'tagline@hi', 'Namaste');

      expect(form.value, {...initial, 'tagline@hi': 'Namaste'});
    });

    testWidgets('Issue 61: the default says what it is for, once, and only '
        'under the default input', (tester) async {
      await _pump(tester, inputs(), initialValue: initial);

      expect(find.text(TranslatedTextInputs.defaultHelp), findsOneWidget);
      expect(
        find.descendant(
          of: fieldWithId('tagline'),
          matching: find.text(TranslatedTextInputs.defaultHelp),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Issue 61: the translations are set in from the default and '
        'stacked under it', (tester) async {
      await _pump(tester, inputs(), initialValue: initial);

      final base = tester.getTopLeft(fieldWithId('tagline'));
      final mr = tester.getTopLeft(fieldWithId('tagline@mr'));
      final hi = tester.getTopLeft(fieldWithId('tagline@hi'));
      expect(mr.dx - base.dx, TranslatedTextInputs.translationIndent);
      expect(hi.dx, mr.dx);
      expect(mr.dy, greaterThan(base.dy));
      expect(hi.dy, greaterThan(mr.dy));
    });

    testWidgets('Issue 61: every input asks for the keyboard given, and '
        'multiline makes each two to four lines', (tester) async {
      await _pump(
        tester,
        inputs(
          languages: const ['mr'],
          keyboardType: TextInputType.streetAddress,
        ),
      );
      for (final id in ['tagline', 'tagline@mr']) {
        expect(_editable(tester, id).keyboardType, TextInputType.streetAddress);
        expect(_editable(tester, id).maxLines, 1);
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await _pump(tester, inputs(languages: const ['mr'], multiline: true));
      for (final id in ['tagline', 'tagline@mr']) {
        expect(_editable(tester, id).keyboardType, TextInputType.multiline);
        expect(_editable(tester, id).minLines, 2);
        expect(_editable(tester, id).maxLines, 4);
      }
    });

    testWidgets('Issue 61: with the form off no input responds', (
      tester,
    ) async {
      final form = await _pump(
        tester,
        inputs(),
        initialValue: initial,
        enabled: false,
      );

      expect(form.fields, hasLength(3));
      await expectNoFieldResponds(tester);
    });

    testWidgets('Issue 61: it fits a phone with three languages', (
      tester,
    ) async {
      await _pump(
        tester,
        inputs(languages: const ['mr', 'hi', 'kok'], multiline: true),
        initialValue: initial,
        size: kPhoneSurface,
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getTopRight(fieldWithId('tagline@kok')).dx,
        lessThanOrEqualTo(kPhoneSurface.width - 16),
      );
    });
  });
}
