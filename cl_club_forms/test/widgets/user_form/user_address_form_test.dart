// Issue 61, UserAddressForm. Points that do not apply: it has no rule
// across fields, no required field and no parameter that hides or locks a
// field. The form has no button of its own. Its values are its fields as
// typed: nothing is trimmed here (the host's adapter does).
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/account_user_form_harness.dart';
import '../../support/form_harness.dart';

const String _line1 = UserFormFields.addrLine1Id;
const String _line2 = UserFormFields.addrLine2Id;
const String _city = UserFormFields.cityId;
const String _state = UserFormFields.stateId;
const String _pincode = UserFormFields.pincodeId;

const _badPincode = 'Enter a valid 6-digit pincode';

Map<String, dynamic> _address() => {
  _line1: '12 MG Road',
  _line2: 'Camp',
  _city: 'Pune',
  _state: 'Maharashtra',
  _pincode: '411001',
};

Future<UserAddressFormState> _pump(
  WidgetTester tester, {
  Map<String, dynamic>? initialValues,
  bool enabled = true,
  Size size = kFormSurface,
}) async {
  final key = GlobalKey<UserAddressFormState>();
  await pumpForm(
    tester,
    UserAddressForm(
      key: key,
      initialValues: initialValues ?? _address(),
      enabled: enabled,
    ),
    size: size,
  );
  return key.currentState!;
}

void main() {
  group('Issue 61: UserAddressForm', () {
    testWidgets('Issue 61: it shows two lines, city, state and pincode, '
        'none required, every row stacked', (tester) async {
      await _pump(tester);

      expect(rowLabels(tester), [
        'Address line 1',
        'Address line 2',
        'City',
        'State',
        'Pincode',
      ]);
      expect(fieldIds(tester), UserFormFields.addressIds);
      expect(find.text('Maharashtra'), findsOneWidget);
      expect(sideBySide(tester, _state, _pincode), isFalse);
      expectLabelsAreRows(tester);
      expectNoHostChrome(tester);
    });

    testWidgets('Issue 61: a pincode of five digits is refused on its '
        'field, and the message goes once it has six', (tester) async {
      final state = await _pump(tester);
      await enterField(tester, _pincode, '41100');

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expectMessageOn(_pincode, _badPincode);

      await enterField(tester, _pincode, '411002');
      expect(state.validate()![_pincode], '411002');
      await tester.pumpAndSettle();
      expect(find.text(_badPincode), findsNothing);
    });

    testWidgets('Issue 61: a pincode of seven digits is refused on its '
        'field', (tester) async {
      final state = await _pump(tester);
      await enterField(tester, _pincode, '4110011');

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expectMessageOn(_pincode, _badPincode);
    });

    testWidgets('Issue 61: a pincode with a letter is refused on its '
        'field', (tester) async {
      final state = await _pump(tester);
      await enterField(tester, _pincode, '4110a1');

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expectMessageOn(_pincode, _badPincode);
    });

    testWidgets('Issue 61: the seeded address comes back unchanged under '
        'exactly the five address ids', (tester) async {
      final state = await _pump(tester);

      expect(state.isDirty, isFalse);
      final values = state.validate();

      expect(values, _address());
      expect(values!.keys, UserFormFields.addressIds);
    });

    testWidgets('Issue 61: what is typed and picked comes back as typed', (
      tester,
    ) async {
      final state = await _pump(tester);
      await enterField(tester, _line1, ' 7 FC Road ');
      await enterField(tester, _line2, '');
      await setField(tester, state, _state, 'Goa');

      expect(state.validate(), {
        _line1: ' 7 FC Road ',
        _line2: '',
        _city: 'Pune',
        _state: 'Goa',
        _pincode: '411001',
      });
    });

    testWidgets('Issue 61: a member with no address may save it empty: '
        'the texts come back empty and the state null', (tester) async {
      final state = await _pump(tester, initialValues: const {});

      expect(find.text('Select state'), findsOneWidget);
      expect(state.validate(), {
        _line1: '',
        _line2: '',
        _city: '',
        _state: null,
        _pincode: '',
      });
    });

    testWidgets('Issue 61: values of other sections given to it are '
        'neither shown nor returned', (tester) async {
      final state = await _pump(
        tester,
        initialValues: {
          ..._address(),
          UserFormFields.emailId: 'robin@example.test',
        },
      );

      expect(find.text('robin@example.test'), findsNothing);
      expect(state.validate(), _address());
    });

    testWidgets('Issue 61: isDirty follows each text, and is false again '
        'when it is retyped as it was', (tester) async {
      final state = await _pump(tester);
      expect(state.isDirty, isFalse);

      for (final id in [_line1, _line2, _city, _pincode]) {
        final before = _address()[id] as String;
        await enterField(tester, id, '${before}1');
        expect(state.isDirty, isTrue, reason: id);
        await enterField(tester, id, before);
        expect(state.isDirty, isFalse, reason: id);
      }
    });

    testWidgets('Issue 61: isDirty follows the state picked, and is false '
        'again when the first one is put back', (tester) async {
      final state = await _pump(tester, initialValues: const {});

      await pickOption(tester, _state, 'Assam');
      expect(heldValue(state, _state), 'Assam');
      expect(state.isDirty, isTrue);

      await setField(tester, state, _state, null);
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: a refusal shows on the pincode and inline, and '
        'the form saves again afterwards', (tester) async {
      final state = await _pump(tester);

      await expectShowsServerErrors(tester, state, _pincode);

      state.showErrors(
        fieldErrors: const {_pincode: 'No such pincode.'},
        formError: 'Could not save the address.',
      );
      await tester.pumpAndSettle();
      expectMessageOn(_pincode, 'No such pincode.');
      expectInlineMessage('Could not save the address.');

      await enterField(tester, _pincode, '411002');
      expect(state.validate()![_pincode], '411002');
      await tester.pumpAndSettle();
      expect(find.text('No such pincode.'), findsNothing);
      expect(find.text('Could not save the address.'), findsNothing);
    });

    testWidgets('Issue 61: with enabled off no field takes a tap and the '
        'state does not open', (tester) async {
      final state = await _pump(
        tester,
        initialValues: const {},
        enabled: false,
      );

      expectEveryFieldOff(tester);
      expect(fieldIds(tester), UserFormFields.addressIds);
      await expectTapsIgnored(tester, [_line1, _line2, _city, _pincode]);
      await tapSelect(tester, _state);
      expect(find.text('Assam'), findsNothing);
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: with enabled on a tap gives a field the focus '
        'and opens the state', (tester) async {
      await _pump(tester, initialValues: const {});

      await tapField(tester, _city);
      expect(hasFocus(tester, _city), isTrue);
      await tapSelect(tester, _state);
      expect(find.text('Assam'), findsOneWidget);
    });

    testWidgets('Issue 61: it fits a phone, with the longest state and '
        'its message showing', (tester) async {
      final state = await _pump(
        tester,
        initialValues: {
          ..._address(),
          _state: 'Dadra and Nagar Haveli and Daman and Diu',
          _pincode: '1',
        },
        size: kPhoneSurface,
      );
      expect(tester.takeException(), isNull);

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();

      expect(find.text(_badPincode), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
