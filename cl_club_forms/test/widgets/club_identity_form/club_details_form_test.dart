import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'club_identity_form_pump.dart';

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
}
