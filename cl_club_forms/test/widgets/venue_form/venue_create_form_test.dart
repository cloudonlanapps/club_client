import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/admin_forms_checks.dart';
import '../../support/form_harness.dart';

// Against the list of club_client#61: VenueCreateForm has one validated
// field (the name) and no rule across fields; no parameter hides or locks a
// field; it draws no heading and no button.

typedef _F = VenueFormFields;

Widget _wrap(Widget child) => ShadApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

Future<void> _setSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1024, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Finder _fieldById(String id) =>
    find.byWidgetPredicate((w) => w is ShadInputFormField && w.id == id);

void main() {
  testWidgets('blocks submit and runs validation when name is empty', (
    tester,
  ) async {
    await _setSurface(tester);
    final key = GlobalKey<VenueCreateFormState>();
    await tester.pumpWidget(
      _wrap(
        VenueCreateForm(
          key: key,
          initialValues: VenueCreateForm.emptyValues,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final values = key.currentState!.validate();
    await tester.pumpAndSettle();

    expect(values, isNull, reason: 'empty name must fail validation');
    expect(find.text('Venue name is required'), findsOneWidget);
  });

  testWidgets('accepts and submits initial values (not defaults)', (
    tester,
  ) async {
    await _setSurface(tester);
    final key = GlobalKey<VenueCreateFormState>();
    await tester.pumpWidget(
      _wrap(
        VenueCreateForm(
          key: key,
          initialValues: const {
            'name': 'Main Arena',
            'address': '1 Rink Rd',
            'description': '',
            'mapUri': '',
            'isDefault': true,
            'isFeatured': false,
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final submitted = key.currentState!.validate();
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted!['name'], 'Main Arena');
    expect(submitted['address'], '1 Rink Rd');
    // The toggle reflects the passed initial value, not the `false` default.
    expect(submitted['isDefault'], true);
  });

  testWidgets('isDirty is false initially and true after a field change', (
    tester,
  ) async {
    await _setSurface(tester);
    final key = GlobalKey<VenueCreateFormState>();
    await tester.pumpWidget(
      _wrap(
        VenueCreateForm(
          key: key,
          initialValues: const {
            'name': 'Main Arena',
            'address': '',
            'description': '',
            'mapUri': '',
            'isDefault': false,
            'isFeatured': false,
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      key.currentState!.isDirty,
      isFalse,
      reason: 'unchanged form must not be dirty (no discard prompt)',
    );

    await tester.enterText(_fieldById('name'), 'Practice Rink');
    await tester.pump();

    expect(
      key.currentState!.isDirty,
      isTrue,
      reason: 'editing a field marks the form dirty (discard prompt)',
    );
  });

  group('Issue 61: VenueCreateForm', () {
    const seeded = <String, dynamic>{
      _F.nameId: 'Main Arena',
      _F.addressId: '1 Rink Rd',
      _F.descriptionId: 'Two sheets of ice',
      _F.mapUriId: 'https://maps.example/arena',
      _F.isDefaultId: true,
      _F.isFeaturedId: false,
    };

    Future<VenueCreateFormState> pump(
      WidgetTester tester, {
      Map<String, dynamic>? initialValues,
      bool enabled = true,
    }) async {
      final key = GlobalKey<VenueCreateFormState>();
      await pumpForm(
        tester,
        VenueCreateForm(
          key: key,
          initialValues: initialValues,
          enabled: enabled,
        ),
      );
      return key.currentState!;
    }

    Future<Map<String, dynamic>?> validate(
      WidgetTester tester,
      VenueCreateFormState state,
    ) async {
      final values = state.validate();
      await tester.pumpAndSettle();
      return values;
    }

    Finder toggle(String id) => find.descendant(
      of: fieldWithId(id),
      matching: find.byType(ShadSwitch),
    );

    testWidgets('Issue 61: it shows its four text fields as labelled rows, '
        'the name required, and its two switches', (tester) async {
      await pump(tester);

      expect(rowLabels(tester), [
        'Venue name *',
        'Address',
        'Description',
        'Map link',
      ]);
      expectLabelsAreRows(tester);
      expect(formOf(tester).fields.keys, {
        _F.nameId,
        _F.addressId,
        _F.descriptionId,
        _F.mapUriId,
        _F.isDefaultId,
        _F.isFeaturedId,
      });
      for (final (id, label) in [
        (_F.isDefaultId, 'Default venue'),
        (_F.isFeaturedId, 'Featured'),
      ]) {
        expect(
          find.descendant(of: fieldWithId(id), matching: find.text(label)),
          findsOneWidget,
        );
      }
    });

    testWidgets('Issue 61: it draws no heading and no button', (tester) async {
      await pump(tester, initialValues: seeded);

      expectNoHostChrome(tester);
      expect(find.byType(ShadButton), findsNothing);
    });

    testWidgets('Issue 61: a blank name is refused on the field', (
      tester,
    ) async {
      final state = await pump(tester);
      await enterField(tester, _F.nameId, '   ');

      expect(await validate(tester, state), isNull);
      expectFieldError(_F.nameId, 'Venue name is required');
    });

    testWidgets('Issue 61: a name of one character is refused on the field, '
        'one of two accepted', (tester) async {
      final state = await pump(tester);
      await enterField(tester, _F.nameId, 'A');

      expect(await validate(tester, state), isNull);
      expectFieldError(_F.nameId, 'At least 2 characters');

      await enterField(tester, _F.nameId, 'R1');
      expect(await validate(tester, state), isNotNull);
      expect(find.text('At least 2 characters'), findsNothing);
    });

    testWidgets('Issue 61: without initial values it starts from '
        'emptyValues, and only the name is needed', (tester) async {
      final state = await pump(tester);

      expect(state.initialValues, VenueCreateForm.emptyValues);
      expect(VenueCreateForm.emptyValues, {
        _F.nameId: '',
        _F.addressId: '',
        _F.descriptionId: '',
        _F.mapUriId: '',
        _F.isDefaultId: false,
        _F.isFeaturedId: false,
      });

      await enterField(tester, _F.nameId, 'Main Arena');
      expect(await validate(tester, state), {
        ...VenueCreateForm.emptyValues,
        _F.nameId: 'Main Arena',
      });
    });

    testWidgets('Issue 61: validate returns exactly the six values, as the '
        'fields hold them', (tester) async {
      final state = await pump(tester);
      await enterField(tester, _F.nameId, ' Main Arena ');
      await enterField(tester, _F.addressId, '1 Rink Rd');
      await enterField(tester, _F.descriptionId, 'Two sheets of ice');
      await enterField(tester, _F.mapUriId, 'https://maps.example/arena');
      await tester.tap(toggle(_F.isFeaturedId));
      await tester.pumpAndSettle();

      final values = await validate(tester, state);

      // Not trimmed here: the host's adapter trims the texts.
      expect(values, {
        _F.nameId: ' Main Arena ',
        _F.addressId: '1 Rink Rd',
        _F.descriptionId: 'Two sheets of ice',
        _F.mapUriId: 'https://maps.example/arena',
        _F.isDefaultId: false,
        _F.isFeaturedId: true,
      });
      expect(values![_F.isDefaultId], isA<bool>());
      expect(values[_F.nameId], isA<String>());
    });

    testWidgets('Issue 61: seeded values come back unchanged', (tester) async {
      final state = await pump(tester, initialValues: seeded);

      expect(state.isDirty, isFalse);
      expect(await validate(tester, state), seeded);
      expect(
        tester.widget<ShadSwitch>(toggle(_F.isDefaultId)).value,
        isTrue,
      );
      expect(
        tester.widget<ShadSwitch>(toggle(_F.isFeaturedId)).value,
        isFalse,
      );
    });

    testWidgets('Issue 61: typing in any text field dirties it, and typing '
        'the old text back cleans it', (tester) async {
      final state = await pump(tester, initialValues: seeded);

      for (final id in [
        _F.nameId,
        _F.addressId,
        _F.descriptionId,
        _F.mapUriId,
      ]) {
        await enterField(tester, id, 'changed');
        expect(state.isDirty, isTrue, reason: id);
        await enterField(tester, id, seeded[id] as String);
        expect(state.isDirty, isFalse, reason: id);
      }
    });

    testWidgets('Issue 61: either switch dirties it, and switching back '
        'cleans it', (tester) async {
      final state = await pump(tester, initialValues: seeded);

      for (final id in [_F.isDefaultId, _F.isFeaturedId]) {
        await tester.tap(toggle(id));
        await tester.pumpAndSettle();
        expect(state.isDirty, isTrue, reason: id);
        expect(formOf(tester).value[id], isNot(seeded[id]));

        await tester.tap(toggle(id));
        await tester.pumpAndSettle();
        expect(state.isDirty, isFalse, reason: id);
      }
    });

    testWidgets('Issue 61: showErrors puts a message on a field and one '
        'inline', (tester) async {
      final state = await pump(tester);

      await expectShowsServerErrors(tester, state, _F.mapUriId);
    });

    testWidgets('Issue 61: after a refused name it validates and returns '
        'its values again', (tester) async {
      final state = await pump(tester, initialValues: seeded);

      expect(
        await expectSavesAfterRefusal(tester, state, _F.nameId),
        seeded,
      );
    });

    testWidgets('Issue 61: with enabled false no field responds', (
      tester,
    ) async {
      await pump(tester, initialValues: seeded, enabled: false);

      await expectNoFieldResponds(tester);
    });

    testWidgets('Issue 61: it fits a phone, its switches wrapped', (
      tester,
    ) async {
      await expectFitsPhone(
        tester,
        const VenueCreateForm(initialValues: seeded),
      );
      expect(toggle(_F.isDefaultId), findsOneWidget);
      expect(toggle(_F.isFeaturedId), findsOneWidget);
    });

    testWidgets('Issue 61: at 240 wide the second switch drops under the '
        'first', (tester) async {
      await pumpForm(
        tester,
        const VenueCreateForm(),
        size: const Size(240, 844),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getTopLeft(toggle(_F.isFeaturedId)).dy,
        greaterThan(tester.getBottomLeft(toggle(_F.isDefaultId)).dy),
      );
    });
  });
}
