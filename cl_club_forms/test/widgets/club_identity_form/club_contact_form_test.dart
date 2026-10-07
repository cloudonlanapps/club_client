import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'club_identity_form_pump.dart';

typedef _F = ClubContactFormFields;

const _initial = <String, dynamic>{
  _F.phoneNumberId: '+10000000000',
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
        _F.phoneNumberId: '+10000000000',
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
}
