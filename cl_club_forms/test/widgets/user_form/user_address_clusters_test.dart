// The field clusters of the user forms that hold the address.
// Each is mounted alone in a bare ShadForm. A cluster has no validate() or
// isDirty of its own (the embedding form has) and no rule across fields;
// those points are tested on the forms.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/user_form/indian_states.dart';
import 'package:cl_club_forms/src/widgets/user_form/user_address_fields.dart';
import 'package:cl_club_forms/src/widgets/user_form/user_field_pair.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/account_user_form_harness.dart';
import '../../support/form_harness.dart';

const String _line1 = UserFormFields.addrLine1Id;
const String _line2 = UserFormFields.addrLine2Id;
const String _city = UserFormFields.cityId;
const String _state = UserFormFields.stateId;
const String _pincode = UserFormFields.pincodeId;

/// Narrower than `UserFieldPair.sideBySideMinWidth` once padded.
const _narrow = Size(480, 2400);

void main() {
  group('Issue 61: UserAddressFields', () {
    testWidgets('Issue 61: it shows two lines, city, state and pincode, '
        'none required', (tester) async {
      await pumpCluster(tester, const UserAddressFields());

      expect(rowLabels(tester), [
        'Address line 1',
        'Address line 2',
        'City',
        'State',
        'Pincode',
      ]);
      expect(fieldIds(tester), [_line1, _line2, _city, _state, _pincode]);
      expect(find.text('Select state'), findsOneWidget);
      expectLabelsAreRows(tester);
      expectNoHostChrome(tester);
    });

    testWidgets('Issue 61: left empty it is valid, the texts empty and the '
        'state null', (tester) async {
      final form = await pumpCluster(
        tester,
        const UserAddressFields(),
        initial: UserFormAssembly.seed(UserFormFields.addressIds, null),
      );

      expect(form.saveAndValidate(), isTrue);
      expect(form.value, {
        _line1: '',
        _line2: '',
        _city: '',
        _state: null,
        _pincode: '',
      });
    });

    testWidgets('Issue 61: a pincode of five digits is refused on its '
        'field and one of six is taken', (tester) async {
      final form = await pumpCluster(tester, const UserAddressFields());
      await enterField(tester, _pincode, '41100');

      expect(form.saveAndValidate(), isFalse);
      await tester.pumpAndSettle();
      expectMessageOn(_pincode, 'Enter a valid 6-digit pincode');

      await enterField(tester, _pincode, '411001');
      expect(form.saveAndValidate(), isTrue);
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid 6-digit pincode'), findsNothing);
    });

    testWidgets('Issue 61: a pincode with a letter is refused on its field', (
      tester,
    ) async {
      final form = await pumpCluster(tester, const UserAddressFields());
      await enterField(tester, _pincode, '41100a');

      expect(form.saveAndValidate(), isFalse);
      await tester.pumpAndSettle();
      expectMessageOn(_pincode, 'Enter a valid 6-digit pincode');
    });

    testWidgets('Issue 61: the state offers the states and holds the one '
        'picked', (tester) async {
      final form = await pumpCluster(tester, const UserAddressFields());

      await tapSelect(tester, _state);
      expect(find.text(indianStates.first), findsOneWidget);
      await tester.tap(find.text('Assam'));
      await tester.pumpAndSettle();

      expect(indianStates, contains('Assam'));
      expect(form.value[_state], 'Assam');
      expect(find.text('Select state'), findsNothing);
    });

    testWidgets("Issue 61: it starts from the form's values, the state "
        'included, and asks for the right keyboards', (tester) async {
      final form = await pumpCluster(
        tester,
        const UserAddressFields(),
        initial: const {
          _line1: '12 MG Road',
          _city: 'Pune',
          _state: 'Maharashtra',
          _pincode: '411001',
        },
      );

      expect(find.text('Maharashtra'), findsOneWidget);
      expect(form.value[_state], 'Maharashtra');
      expect(editableOf(tester, _line1).controller.text, '12 MG Road');
      expect(editableOf(tester, _pincode).controller.text, '411001');
      for (final id in [_line1, _line2, _city]) {
        expect(
          editableOf(tester, id).keyboardType,
          TextInputType.streetAddress,
        );
      }
      expect(editableOf(tester, _pincode).keyboardType, TextInputType.number);
    });

    testWidgets('Issue 61: state and pincode sit side by side where there '
        'is room and follow pairMinWidth', (tester) async {
      await pumpCluster(tester, const UserAddressFields());
      expect(sideBySide(tester, _state, _pincode), isTrue);

      await pumpCluster(tester, const UserAddressFields(), size: _narrow);
      expect(sideBySide(tester, _state, _pincode), isFalse);

      await pumpCluster(
        tester,
        const UserAddressFields(pairMinWidth: UserFieldPair.never),
      );
      expect(sideBySide(tester, _state, _pincode), isFalse);
    });

    testWidgets('Issue 61: with enabled off nothing takes a tap and the '
        'state does not open', (tester) async {
      await pumpCluster(tester, const UserAddressFields(enabled: false));

      expectEveryFieldOff(tester);
      await expectTapsIgnored(tester, [_line1, _line2, _city, _pincode]);
      await tapSelect(tester, _state);
      expect(find.text('Assam'), findsNothing);
    });
  });
}
