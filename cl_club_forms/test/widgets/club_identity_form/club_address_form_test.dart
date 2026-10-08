import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/admin_forms_checks.dart';
import '../../support/form_harness.dart';
import 'club_identity_form_pump.dart';

// Against the list of club_client#61: no field of ClubAddressForm is
// required and none has a validator; there is one rule across fields (a
// translation needs its default text); `languages` adds inputs but hides or
// locks none; the form draws no heading and no button.

typedef _F = ClubAddressFormFields;

const _initial = <String, dynamic>{
  _F.cityId: FormTranslatedText('Example City', {'mr': 'Udaharan'}),
  _F.postalCodeId: '000000',
};

Future<GlobalKey<ClubAddressFormState>> _pump(
  WidgetTester tester, {
  List<String> languages = const ['mr'],
}) async {
  final key = GlobalKey<ClubAddressFormState>();
  await pumpClubIdentityForm(
    tester,
    ClubAddressForm(
      key: key,
      initialValues: _initial,
      languages: languages,
    ),
  );
  return key;
}

void main() {
  group('Issue 58: ClubAddressForm', () {
    testWidgets('Issue 58: ClubAddressForm has its five fields, no card and '
        'no button', (tester) async {
      await _pump(tester, languages: const []);

      for (final id in _F.labels.keys) {
        expect(clubIdentityInput(id), findsOneWidget, reason: id);
      }
      for (final label in _F.labels.values) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.byType(EditableText), findsNWidgets(_F.labels.length));
      expectNoCardAndNoButton();
    });

    testWidgets('Issue 58: ClubAddressForm shows an input per language for '
        'each translatable field, and returns its own fields', (tester) async {
      final key = await _pump(tester);

      for (final id in _F.translatedIds) {
        expect(clubIdentityInput(translationId(id, 'mr')), findsOneWidget);
      }
      expect(find.text('Udaharan'), findsOneWidget);
      expect(key.currentState!.isDirty, isFalse);

      await enterClubIdentityText(tester, _F.addressId, ' 1 Example Street ');
      expect(key.currentState!.isDirty, isTrue);

      expect(key.currentState!.validate(), {
        _F.postalCodeId: '000000',
        _F.addressId: const FormTranslatedText('1 Example Street'),
        _F.addressLine2Id: const FormTranslatedText(''),
        _F.cityId: const FormTranslatedText('Example City', {
          'mr': 'Udaharan',
        }),
        _F.stateId: const FormTranslatedText(''),
      });
    });

    testWidgets('Issue 58: ClubAddressForm refuses a translation without a '
        'default text, naming its own field', (tester) async {
      final key = await _pump(tester);

      await enterClubIdentityText(
        tester,
        translationId(_F.stateId, 'mr'),
        'MH',
      );

      expect(key.currentState!.validate(), isNull);
      await tester.pump();
      expect(
        find.text('State has a translation but no default text.'),
        findsOneWidget,
      );
    });
  });

  group('Issue 61: ClubAddressForm', () {
    Future<Map<String, dynamic>?> validate(
      WidgetTester tester,
      GlobalKey<ClubAddressFormState> key,
    ) async {
      final values = key.currentState!.validate();
      await tester.pumpAndSettle();
      return values;
    }

    testWidgets('Issue 61: without languages it shows its five fields as '
        'labelled rows, none required', (tester) async {
      await _pump(tester, languages: const []);

      expect(rowLabels(tester), [
        'Address',
        'Address line 2',
        'City',
        'State',
        'Postal code',
      ]);
      expectLabelsAreRows(tester);
    });

    testWidgets('Issue 61: with two languages each translatable field gets '
        'a row per language, and the postal code none', (tester) async {
      await _pump(tester, languages: const ['mr', 'hi']);

      expect(rowLabels(tester), [
        for (final label in ['Address', 'Address line 2', 'City', 'State']) ...[
          label,
          '$label (mr)',
          '$label (hi)',
        ],
        'Postal code',
      ]);
      expectLabelsAreRows(tester);
      expect(formOf(tester).fields, hasLength(13));
    });

    testWidgets('Issue 61: an empty form is valid, and returns its five '
        'values empty', (tester) async {
      final key = GlobalKey<ClubAddressFormState>();
      await pumpClubIdentityForm(
        tester,
        ClubAddressForm(key: key, initialValues: const {}),
      );

      expect(await validate(tester, key), {
        _F.postalCodeId: '',
        for (final id in _F.translatedIds) id: const FormTranslatedText(''),
      });
    });

    testWidgets('Issue 61: the postal code takes any text, and comes back '
        'trimmed', (tester) async {
      final key = await _pump(tester);
      await enterClubIdentityText(tester, _F.postalCodeId, ' AB1 2CD ');

      final values = await validate(tester, key);
      expect(values![_F.postalCodeId], 'AB1 2CD');
      expect(values[_F.postalCodeId], isA<String>());
      expect(values[_F.cityId], isA<FormTranslatedText>());
    });

    testWidgets('Issue 61: translations in two languages come back '
        'together, and one emptied is dropped', (tester) async {
      final key = await _pump(tester, languages: const ['mr', 'hi']);
      await enterClubIdentityText(
        tester,
        translationId(_F.cityId, 'hi'),
        ' Udaharan Nagar ',
      );

      expect(
        (await validate(tester, key))![_F.cityId],
        const FormTranslatedText('Example City', {
          'mr': 'Udaharan',
          'hi': 'Udaharan Nagar',
        }),
      );

      await enterClubIdentityText(tester, translationId(_F.cityId, 'mr'), '');
      expect(
        (await validate(tester, key))![_F.cityId],
        const FormTranslatedText('Example City', {'hi': 'Udaharan Nagar'}),
      );
    });

    testWidgets('Issue 61: the refused translation passes once its default '
        'text is typed', (tester) async {
      final key = await _pump(tester);
      await enterClubIdentityText(
        tester,
        translationId(_F.stateId, 'mr'),
        'MH',
      );
      expect(await validate(tester, key), isNull);
      expect(find.textContaining('no default text'), findsOneWidget);

      await enterClubIdentityText(tester, _F.stateId, 'Maharashtra');

      expect(
        (await validate(tester, key))![_F.stateId],
        const FormTranslatedText('Maharashtra', {'mr': 'MH'}),
      );
      expect(find.textContaining('no default text'), findsNothing);
    });

    testWidgets('Issue 61: typing dirties it, in a plain field or a '
        'translation, and typing the old text back cleans it', (tester) async {
      final key = await _pump(tester);
      expect(key.currentState!.isDirty, isFalse);

      await enterClubIdentityText(tester, _F.postalCodeId, '111111');
      expect(key.currentState!.isDirty, isTrue);
      await enterClubIdentityText(tester, _F.postalCodeId, '000000');
      expect(key.currentState!.isDirty, isFalse);

      final id = translationId(_F.cityId, 'mr');
      await enterClubIdentityText(tester, id, '');
      expect(key.currentState!.isDirty, isTrue);
      await enterClubIdentityText(tester, id, 'Udaharan');
      expect(key.currentState!.isDirty, isFalse);
    });

    testWidgets('Issue 61: showErrors puts a message on a field and one '
        'inline', (tester) async {
      final key = await _pump(tester);

      await expectShowsServerErrors(tester, key.currentState!, _F.postalCodeId);
    });

    testWidgets('Issue 61: after a refused city it validates and returns '
        'its values again', (tester) async {
      final key = await _pump(tester);

      final values = await expectSavesAfterRefusal(
        tester,
        key.currentState!,
        _F.cityId,
      );
      expect(values[_F.postalCodeId], '000000');
    });

    testWidgets('Issue 61: with enabled false no field responds, '
        'translations included', (tester) async {
      await pumpForm(
        tester,
        const ClubAddressForm(
          initialValues: _initial,
          languages: ['mr'],
          enabled: false,
        ),
      );

      expect(formOf(tester).fields, hasLength(9));
      await expectNoFieldResponds(tester);
    });

    testWidgets('Issue 61: it fits a phone with two languages', (tester) async {
      await expectFitsPhone(
        tester,
        const ClubAddressForm(
          initialValues: _initial,
          languages: ['mr', 'hi'],
        ),
      );
    });
  });
  group('Issue 94: ClubAddressForm', () {
    testWidgets('Issue 94: on screen and turned off, every field is off and '
        'takes no pointer; turned on again, every field responds', (
      tester,
    ) async {
      await expectOffThenOnAgain(
        tester,
        ({required enabled}) => ClubAddressForm(
          initialValues: _initial,
          languages: const ['mr'],
          enabled: enabled,
        ),
        inputs: 9,
      );
    });
  });
}
