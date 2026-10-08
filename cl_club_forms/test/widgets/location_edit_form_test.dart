import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/admin_forms_checks.dart';
import '../support/form_harness.dart';

// Against the list of club_client#61: LocationEditForm has two optional
// text fields, so no field is required, none has a validator and there is no
// rule across fields; no parameter hides or locks a field; it draws no
// heading and no button.
typedef _F = LocationEditFormFields;

Widget _wrap(Widget child) => ShadApp(home: Scaffold(body: child));

void main() {
  testWidgets('respects initial values and returns them trimmed', (
    tester,
  ) async {
    final key = GlobalKey<LocationEditFormState>();
    await tester.pumpWidget(
      _wrap(
        LocationEditForm(
          key: key,
          initialAddress: '1 Rink Rd',
          initialMapUri: 'https://maps.example/x',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 Rink Rd'), findsOneWidget);

    final result = key.currentState!.validate();
    expect(result, isNotNull);
    expect(result![LocationEditFormFields.addressId], '1 Rink Rd');
    expect(result[LocationEditFormFields.mapUriId], 'https://maps.example/x');
  });

  testWidgets('returns empty strings when started blank', (tester) async {
    final key = GlobalKey<LocationEditFormState>();
    await tester.pumpWidget(
      _wrap(
        LocationEditForm(
          key: key,
          initialAddress: '',
          initialMapUri: '',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final result = key.currentState!.validate();
    expect(result, {
      LocationEditFormFields.addressId: '',
      LocationEditFormFields.mapUriId: '',
    });
  });

  group('Issue 61: LocationEditForm', () {
    Future<LocationEditFormState> pump(
      WidgetTester tester, {
      String address = '1 Rink Rd',
      String mapUri = 'https://maps.example/x',
      bool enabled = true,
    }) async {
      final key = GlobalKey<LocationEditFormState>();
      await pumpForm(
        tester,
        LocationEditForm(
          key: key,
          initialAddress: address,
          initialMapUri: mapUri,
          enabled: enabled,
        ),
      );
      return key.currentState!;
    }

    testWidgets('Issue 61: it shows the address and the map link as '
        'labelled rows, neither required', (tester) async {
      await pump(tester);

      expect(rowLabels(tester), ['Address', 'Map link']);
      expectLabelsAreRows(tester);
      expect(formOf(tester).fields.keys, [_F.addressId, _F.mapUriId]);
    });

    testWidgets('Issue 61: empty, each field shows its hint', (tester) async {
      await pump(tester, address: '', mapUri: '');

      expect(
        find.descendant(
          of: fieldWithId(_F.addressId),
          matching: find.text('Street, city, state'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: fieldWithId(_F.mapUriId),
          matching: find.text('https://maps.google.com/...'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Issue 61: it draws no heading and no button', (tester) async {
      await pump(tester);

      expectNoHostChrome(tester);
      expect(find.byType(ShadButton), findsNothing);
    });

    testWidgets('Issue 61: validate returns exactly the two texts, both '
        'trimmed', (tester) async {
      final state = await pump(tester, address: '', mapUri: '');
      await enterField(tester, _F.addressId, '  2 Rink Rd  ');
      await enterField(tester, _F.mapUriId, ' https://maps.example/y ');

      final values = state.validate();

      expect(values, {
        _F.addressId: '2 Rink Rd',
        _F.mapUriId: 'https://maps.example/y',
      });
      expect(values!.values, everyElement(isA<String>()));
    });

    testWidgets('Issue 61: a field emptied, or left with spaces only, comes '
        'back as an empty text', (tester) async {
      final state = await pump(tester);
      await enterField(tester, _F.addressId, '');
      await enterField(tester, _F.mapUriId, '   ');

      expect(state.validate(), {_F.addressId: '', _F.mapUriId: ''});
    });

    testWidgets('Issue 61: any text is accepted, a map link that is no '
        'link included', (tester) async {
      final state = await pump(tester);
      await enterField(tester, _F.mapUriId, 'behind the mall');

      expect(state.validate()![_F.mapUriId], 'behind the mall');
    });

    testWidgets('Issue 61: typing in either field dirties it, and typing '
        'the old text back cleans it', (tester) async {
      final state = await pump(tester);
      expect(state.isDirty, isFalse);

      await enterField(tester, _F.addressId, '2 Rink Rd');
      expect(state.isDirty, isTrue);
      await enterField(tester, _F.addressId, '1 Rink Rd');
      expect(state.isDirty, isFalse);

      await enterField(tester, _F.mapUriId, '');
      expect(state.isDirty, isTrue);
      await enterField(tester, _F.mapUriId, 'https://maps.example/x');
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: showErrors puts a message on a field and one '
        'inline', (tester) async {
      final state = await pump(tester);

      await expectShowsServerErrors(tester, state, _F.mapUriId);
    });

    testWidgets('Issue 61: after a refusal it validates and returns its '
        'values again', (tester) async {
      final state = await pump(tester);

      expect(await expectSavesAfterRefusal(tester, state, _F.addressId), {
        _F.addressId: '1 Rink Rd',
        _F.mapUriId: 'https://maps.example/x',
      });
    });

    testWidgets('Issue 61: with enabled false no field responds', (
      tester,
    ) async {
      await pump(tester, enabled: false);

      await expectNoFieldResponds(tester);
    });

    testWidgets('Issue 61: it fits a phone', (tester) async {
      await expectFitsPhone(
        tester,
        const LocationEditForm(
          initialAddress: '12 Long Street Name, Some Neighbourhood, A City',
          initialMapUri: 'https://maps.example/a/very/long/link/to/the/rink',
        ),
      );
    });
  });
}
