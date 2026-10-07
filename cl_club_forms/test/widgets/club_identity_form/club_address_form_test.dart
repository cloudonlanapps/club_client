import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'club_identity_form_pump.dart';

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
}
