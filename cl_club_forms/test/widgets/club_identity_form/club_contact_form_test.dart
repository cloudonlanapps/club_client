import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/admin_forms_checks.dart';
import '../../support/form_harness.dart';
import 'club_identity_form_pump.dart';

// Against the list of club_client#61: no field of ClubContactForm is
// required; four have a validator (phone, WhatsApp number, email, Instagram
// link) and there is one rule across fields (a translation needs its default
// text); `languages` adds inputs but hides or locks none; the form draws no
// heading and no button.

typedef _F = ClubContactFormFields;

const _initial = <String, dynamic>{
  _F.phoneNumberId: '+14155550100',
  _F.emailSubjectId: FormTranslatedText('Hello', {'mr': 'Namaskar'}),
};

Future<GlobalKey<ClubContactFormState>> _pump(
  WidgetTester tester, {
  List<String> languages = const ['mr'],
}) async {
  final key = GlobalKey<ClubContactFormState>();
  await pumpClubIdentityForm(
    tester,
    ClubContactForm(
      key: key,
      initialValues: _initial,
      languages: languages,
    ),
  );
  return key;
}

void main() {
  group('Issue 20: ClubIdentityForm', () {
    testWidgets('Issue 20: a phone that is not E.164 is refused', (
      tester,
    ) async {
      final key = await _pump(tester);

      await enterClubIdentityText(tester, _F.phoneNumberId, '98765 43210');

      expect(key.currentState!.validate(), isNull);
      await tester.pump();
      expect(find.textContaining('international format'), findsOneWidget);
    });

    testWidgets('Issue 20: a bad email or relative URL is refused', (
      tester,
    ) async {
      final key = await _pump(tester);

      await enterClubIdentityText(tester, _F.emailId, 'desk-at-club');
      await enterClubIdentityText(
        tester,
        _F.instagramUrlId,
        'instagram.com/club',
      );

      expect(key.currentState!.validate(), isNull);
      await tester.pump();
      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(find.textContaining('full link'), findsOneWidget);
    });

    testWidgets('Issue 20: the declared languages each get an input per '
        'translatable field', (tester) async {
      await _pump(tester, languages: const ['hi']);

      for (final id in _F.translatedIds) {
        expect(clubIdentityInput(translationId(id, 'hi')), findsOneWidget);
      }
    });

    testWidgets('Issue 20: isDirty follows the edits', (tester) async {
      final key = await _pump(tester);
      expect(key.currentState!.isDirty, isFalse);

      await enterClubIdentityText(tester, _F.emailId, 'desk@club.example');
      expect(key.currentState!.isDirty, isTrue);

      await enterClubIdentityText(tester, _F.emailId, '');
      expect(key.currentState!.isDirty, isFalse);
    });
  });

  group('Issue 58: ClubContactForm', () {
    testWidgets('Issue 58: ClubContactForm has its six fields, no card and '
        'no button', (tester) async {
      await _pump(tester, languages: const []);

      for (final id in _F.labels.keys) {
        expect(clubIdentityInput(id), findsOneWidget, reason: id);
      }
      for (final label in _F.labels.values) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.byType(EditableText), findsNWidgets(_F.labels.length));
      expect(find.text(_F.whatsappNumberHelp), findsOneWidget);
      expectNoCardAndNoButton();
    });

    testWidgets('Issue 58: ClubContactForm returns its own fields only, '
        'trimmed', (tester) async {
      final key = await _pump(tester);

      await enterClubIdentityText(
        tester,
        _F.whatsappMessageId,
        '  Hi, I have a question ',
      );

      expect(key.currentState!.validate(), {
        _F.phoneNumberId: '+14155550100',
        _F.whatsappNumberId: '',
        _F.emailId: '',
        _F.instagramUrlId: '',
        _F.whatsappMessageId: const FormTranslatedText(
          'Hi, I have a question',
        ),
        _F.emailSubjectId: const FormTranslatedText('Hello', {
          'mr': 'Namaskar',
        }),
      });
    });

    testWidgets('Issue 58: ClubContactForm refuses a translation without a '
        'default text, naming its own field', (tester) async {
      final key = await _pump(tester);

      await enterClubIdentityText(tester, _F.emailSubjectId, '');

      expect(key.currentState!.validate(), isNull);
      await tester.pump();
      expect(
        find.text('Email subject has a translation but no default text.'),
        findsOneWidget,
      );
    });

    testWidgets('Issue 58: showErrors puts a server refusal on the field it '
        'names and a message under the rows', (tester) async {
      final key = await _pump(tester);

      key.currentState!.showErrors(
        fieldErrors: {_F.emailId: 'Not accepted'},
        formError: 'Could not save.',
      );
      await tester.pump();

      expect(find.text('Not accepted'), findsOneWidget);
      expect(find.text('Could not save.'), findsOneWidget);
    });
  });

  group('Issue 61: ClubContactForm', () {
    const phoneMessage =
        'Use the international format: + and the country code, '
        'digits only (e.g. +919876543210)';
    const urlMessage = 'Enter the full link, starting with https://';

    Future<Map<String, dynamic>?> validate(
      WidgetTester tester,
      GlobalKey<ClubContactFormState> key,
    ) async {
      final values = key.currentState!.validate();
      await tester.pumpAndSettle();
      return values;
    }

    testWidgets('Issue 61: with two languages it shows its six fields and a '
        'row per language under each translatable one, none required', (
      tester,
    ) async {
      await _pump(tester, languages: const ['mr', 'hi']);

      expect(rowLabels(tester), [
        'Phone',
        'WhatsApp number',
        'WhatsApp message',
        'WhatsApp message (mr)',
        'WhatsApp message (hi)',
        'Email',
        'Email subject',
        'Email subject (mr)',
        'Email subject (hi)',
        'Instagram link',
      ]);
      expectLabelsAreRows(tester);
    });

    testWidgets('Issue 61: the WhatsApp message and its translations take '
        'several lines, the other inputs one', (tester) async {
      await _pump(tester);

      int? maxLines(String id) => tester
          .widget<EditableText>(
            find.descendant(
              of: clubIdentityInput(id),
              matching: find.byType(EditableText),
            ),
          )
          .maxLines;
      expect(maxLines(_F.whatsappMessageId), 4);
      expect(maxLines(translationId(_F.whatsappMessageId, 'mr')), 4);
      expect(maxLines(_F.emailSubjectId), 1);
      expect(maxLines(_F.phoneNumberId), 1);
    });

    testWidgets('Issue 61: a phone that is not E.164 shows its message on '
        'the phone', (tester) async {
      final key = await _pump(tester);
      await enterClubIdentityText(tester, _F.phoneNumberId, '09876543210');

      expect(await validate(tester, key), isNull);
      expectFieldError(_F.phoneNumberId, phoneMessage);
    });

    testWidgets('Issue 61: a WhatsApp number that is not E.164 shows its '
        'message on that field, not on the phone', (tester) async {
      final key = await _pump(tester);
      await enterClubIdentityText(
        tester,
        _F.whatsappNumberId,
        '+91 98765 43210',
      );

      expect(await validate(tester, key), isNull);
      expectFieldError(_F.whatsappNumberId, phoneMessage);
    });

    testWidgets('Issue 61: a malformed email shows its message on the '
        'email', (tester) async {
      final key = await _pump(tester);
      await enterClubIdentityText(tester, _F.emailId, 'desk@club');

      expect(await validate(tester, key), isNull);
      expectFieldError(_F.emailId, 'Enter a valid email address');
    });

    testWidgets('Issue 61: a link that is not a full http(s) link shows its '
        'message on the Instagram link', (tester) async {
      final key = await _pump(tester);
      await enterClubIdentityText(
        tester,
        _F.instagramUrlId,
        'ftp://club.example/photos',
      );

      expect(await validate(tester, key), isNull);
      expectFieldError(_F.instagramUrlId, urlMessage);
    });

    testWidgets('Issue 61: well-formed values in all four checked fields '
        'are accepted, and come back trimmed', (tester) async {
      final key = await _pump(tester);
      await enterClubIdentityText(tester, _F.phoneNumberId, ' +919876543210 ');
      await enterClubIdentityText(tester, _F.whatsappNumberId, '+14155550123');
      await enterClubIdentityText(tester, _F.emailId, ' desk@club.example ');
      await enterClubIdentityText(
        tester,
        _F.instagramUrlId,
        ' https://www.instagram.com/club/ ',
      );

      final values = await validate(tester, key);

      expect(values, {
        _F.phoneNumberId: '+919876543210',
        _F.whatsappNumberId: '+14155550123',
        _F.emailId: 'desk@club.example',
        _F.instagramUrlId: 'https://www.instagram.com/club/',
        _F.whatsappMessageId: const FormTranslatedText(''),
        _F.emailSubjectId: const FormTranslatedText('Hello', {
          'mr': 'Namaskar',
        }),
      });
      for (final id in _F.textIds) {
        expect(values![id], isA<String>(), reason: id);
      }
      for (final id in _F.translatedIds) {
        expect(values![id], isA<FormTranslatedText>(), reason: id);
      }
    });

    testWidgets('Issue 61: every field may be left empty', (tester) async {
      final key = GlobalKey<ClubContactFormState>();
      await pumpClubIdentityForm(
        tester,
        ClubContactForm(key: key, initialValues: const {}),
      );

      expect(await validate(tester, key), {
        for (final id in _F.textIds) id: '',
        for (final id in _F.translatedIds) id: const FormTranslatedText(''),
      });
    });

    testWidgets('Issue 61: of two fields with a translation and no default, '
        'the first on the form is named; filling it names the second', (
      tester,
    ) async {
      final key = await _pump(tester);
      await enterClubIdentityText(tester, _F.emailSubjectId, '');
      await enterClubIdentityText(
        tester,
        translationId(_F.whatsappMessageId, 'mr'),
        'Namaskar',
      );

      expect(await validate(tester, key), isNull);
      expect(
        find.text('WhatsApp message has a translation but no default text.'),
        findsOneWidget,
      );
      expect(find.textContaining('Email subject has'), findsNothing);

      await enterClubIdentityText(tester, _F.whatsappMessageId, 'Hello');
      expect(await validate(tester, key), isNull);
      expect(
        find.text('Email subject has a translation but no default text.'),
        findsOneWidget,
      );

      await enterClubIdentityText(tester, _F.emailSubjectId, 'Hello');
      expect(await validate(tester, key), isNotNull);
      expect(find.textContaining('no default text'), findsNothing);
    });

    testWidgets('Issue 61: a translation typed dirties it, and emptying it '
        'cleans it', (tester) async {
      final key = await _pump(tester);
      final id = translationId(_F.whatsappMessageId, 'mr');

      await enterClubIdentityText(tester, id, 'Namaskar');
      expect(key.currentState!.isDirty, isTrue);

      await enterClubIdentityText(tester, id, '');
      expect(key.currentState!.isDirty, isFalse);
    });

    testWidgets('Issue 61: showErrors puts a message on a field and one '
        'inline', (tester) async {
      final key = await _pump(tester);

      await expectShowsServerErrors(
        tester,
        key.currentState!,
        _F.whatsappNumberId,
      );
    });

    testWidgets('Issue 61: after a refused phone it validates and returns '
        'its values again', (tester) async {
      final key = await _pump(tester);

      final values = await expectSavesAfterRefusal(
        tester,
        key.currentState!,
        _F.phoneNumberId,
      );
      expect(values[_F.phoneNumberId], '+14155550100');
    });

    testWidgets('Issue 61: with enabled false no field responds, '
        'translations included', (tester) async {
      await pumpForm(
        tester,
        const ClubContactForm(
          initialValues: _initial,
          languages: ['mr', 'hi'],
          enabled: false,
        ),
      );

      expect(formOf(tester).fields, hasLength(10));
      await expectNoFieldResponds(tester);
    });

    testWidgets('Issue 61: it fits a phone with two languages', (tester) async {
      await expectFitsPhone(
        tester,
        const ClubContactForm(
          initialValues: _initial,
          languages: ['mr', 'hi'],
        ),
      );
    });
  });
}
