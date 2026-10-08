import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_form_fields.dart'
    show AgeEligibilityFormFields;
import 'package:cl_club_forms/src/widgets/form/form_contract.dart';
import 'package:cl_club_forms/src/widgets/form/labeled_form_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _refusal = 'The server refused this.';

/// One form of club_client#55, as its host mounts it.
typedef _Case = ({
  String name,
  Widget Function(Key key, {required bool enabled}) build,
  List<String> requiredLabels,
});

final List<_Case> _cases = [
  (
    name: 'GroupCreateForm',
    build: (key, {required enabled}) => GroupCreateForm(
      key: key,
      enabled: enabled,
      initialValues: {
        ...GroupCreateForm.emptyValues,
        GroupFormFields.modeId: GroupMode.auto,
      },
    ),
    requiredLabels: ['Group Name *'],
  ),
  (
    name: 'GroupEligibilityForm',
    build: (key, {required enabled}) => GroupEligibilityForm(
      key: key,
      enabled: enabled,
      initialValues: {
        ...GroupCreateForm.emptyValues,
        GroupFormFields.modeId: GroupMode.auto,
      },
    ),
    requiredLabels: [],
  ),
  (
    name: 'VenueCreateForm',
    build: (key, {required enabled}) =>
        VenueCreateForm(key: key, enabled: enabled),
    requiredLabels: ['Venue name *'],
  ),
  (
    name: 'LocationEditForm',
    build: (key, {required enabled}) => LocationEditForm(
      key: key,
      enabled: enabled,
      initialValues: const {
        LocationEditFormFields.addressId: '1 Rink Rd',
        LocationEditFormFields.mapUriId: '',
      },
    ),
    requiredLabels: [],
  ),
  (
    name: 'RenameForm',
    build: (key, {required enabled}) => RenameForm(
      key: key,
      enabled: enabled,
      initialValue: 'Juniors',
      label: 'Group Name',
    ),
    requiredLabels: ['Group Name *'],
  ),
];

Future<void> _pump(WidgetTester tester, Widget form) async {
  await tester.binding.setSurfaceSize(const Size(1024, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(body: SingleChildScrollView(child: form)),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _inputs() => find.byWidgetPredicate((w) => w is ShadInputFormField);
Finder _selects() =>
    find.byWidgetPredicate((w) => w is ShadSelectFormField<dynamic>);
Finder _switches() => find.byType(ShadSwitchFormField);

Finder _input(String id) =>
    find.byWidgetPredicate((w) => w is ShadInputFormField && w.id == id);

void main() {
  for (final c in _cases) {
    group('Issue 55: ${c.name} follows the form contract', () {
      testWidgets('Issue 55: ${c.name} labels its fields with LabeledFormRow, '
          'never with their own label', (tester) async {
        await _pump(tester, c.build(GlobalKey(), enabled: true));

        // The age inputs belong to the shared age cluster, which the event
        // forms' change (club_client#54) moves onto the helpers.
        const ageIds = [
          ...AgeEligibilityFormFields.minAgeIds,
          ...AgeEligibilityFormFields.maxAgeIds,
        ];
        final ownLabels = <String, Widget?>{
          for (final f in tester.widgetList<ShadInputFormField>(_inputs()))
            if (!ageIds.contains(f.id)) f.id!: f.label,
          for (final f in tester.widgetList<ShadSelectFormField<dynamic>>(
            _selects(),
          ))
            f.id!: f.label,
          for (final f in tester.widgetList<ShadSwitchFormField>(_switches()))
            f.id!: f.label,
        };
        expect(ownLabels, isNotEmpty);
        expect(ownLabels.values, everyElement(isNull), reason: '$ownLabels');
        expect(find.byType(LabeledFormRow), findsWidgets);
        for (final label in c.requiredLabels) {
          expect(find.text(label), findsOneWidget);
        }
      });

      testWidgets('Issue 55: ${c.name} has no button that submits and its '
          'state gives the host the contract', (tester) async {
        final key = GlobalKey();
        await _pump(tester, c.build(key, enabled: true));

        expect(key.currentState, isA<FormContract>());
        expect(find.byType(ShadButton), findsNothing);
        final contract = key.currentState! as FormContract;
        expect(contract.isDirty, isFalse);
      });

      testWidgets('Issue 55: ${c.name} with enabled false turns every field '
          'off', (tester) async {
        await _pump(tester, c.build(GlobalKey(), enabled: false));

        for (final field in tester.widgetList<ShadInputFormField>(_inputs())) {
          expect(field.enabled, isFalse, reason: 'input ${field.id}');
        }
        for (final field in tester.widgetList<ShadSelectFormField<dynamic>>(
          _selects(),
        )) {
          expect(field.enabled, isFalse, reason: 'select ${field.id}');
        }
        for (final field in tester.widgetList<ShadSwitchFormField>(
          _switches(),
        )) {
          expect(field.enabled, isFalse, reason: 'switch ${field.id}');
        }
      });
    });
  }

  group('Issue 55: the forms show what the server refused', () {
    testWidgets('Issue 55: VenueCreateForm puts a refused Default venue on '
        'its switch', (tester) async {
      final key = GlobalKey<VenueCreateFormState>();
      await _pump(tester, VenueCreateForm(key: key));

      key.currentState!.showErrors(
        fieldErrors: {VenueFormFields.isDefaultId: _refusal},
      );
      await tester.pump();

      expect(find.text(_refusal), findsOneWidget);
    });

    testWidgets('Issue 55: GroupCreateForm shows a refused name on the name '
        'and a form-level refusal inline', (tester) async {
      final key = GlobalKey<GroupCreateFormState>();
      await _pump(tester, GroupCreateForm(key: key));

      key.currentState!.showErrors(
        fieldErrors: {GroupFormFields.nameId: 'Name refused.'},
        formError: _refusal,
      );
      await tester.pump();

      expect(find.text('Name refused.'), findsOneWidget);
      expect(find.text(_refusal), findsOneWidget);
    });

    testWidgets('Issue 55: GroupEligibilityForm puts a refused mode on the '
        'Mode field, and a reset clears the form-level message', (
      tester,
    ) async {
      final key = GlobalKey<GroupEligibilityFormState>();
      await _pump(
        tester,
        GroupEligibilityForm(
          key: key,
          initialValues: {
            ...GroupCreateForm.emptyValues,
            GroupFormFields.modeId: GroupMode.auto,
            GroupFormFields.genderId: GroupGender.girls,
          },
        ),
      );

      key.currentState!.showErrors(
        fieldErrors: {GroupFormFields.modeId: 'Mode refused.'},
        formError: _refusal,
      );
      await tester.pump();
      expect(find.text('Mode refused.'), findsOneWidget);
      expect(find.text(_refusal), findsOneWidget);

      key.currentState!.reset();
      await tester.pumpAndSettle();
      expect(find.text(_refusal), findsNothing);
    });
  });

  group('Issue 55: values and isDirty', () {
    testWidgets('Issue 55: LocationEditForm is dirty only once a field '
        'changes, and returns its values trimmed', (tester) async {
      final key = GlobalKey<LocationEditFormState>();
      await _pump(
        tester,
        LocationEditForm(
          key: key,
          initialValues: const {
            LocationEditFormFields.addressId: '1 Rink Rd',
            LocationEditFormFields.mapUriId: '',
          },
        ),
      );
      expect(key.currentState!.isDirty, isFalse);

      await tester.enterText(
        _input(LocationEditFormFields.addressId),
        '  2 Rink Rd ',
      );
      await tester.pump();

      expect(key.currentState!.isDirty, isTrue);
      expect(key.currentState!.validate(), {
        LocationEditFormFields.addressId: '2 Rink Rd',
        LocationEditFormFields.mapUriId: '',
      });
    });

    testWidgets('Issue 55: RenameForm is dirty only once the text changes', (
      tester,
    ) async {
      final key = GlobalKey<RenameFormState>();
      await _pump(
        tester,
        RenameForm(key: key, initialValue: 'Juniors', label: 'Group Name'),
      );
      expect(key.currentState!.isDirty, isFalse);

      await tester.enterText(_input(RenameFormFields.valueId), 'Seniors');
      await tester.pump();

      expect(key.currentState!.isDirty, isTrue);
      expect(key.currentState!.validate(), {
        RenameFormFields.valueId: 'Seniors',
      });
    });

    testWidgets('Issue 55: a fresh group that visits a criteria mode and '
        'comes back to Manual is not dirty', (tester) async {
      final key = GlobalKey<GroupCreateFormState>();
      await _pump(tester, GroupCreateForm(key: key));
      expect(key.currentState!.isDirty, isFalse);

      await tester.tap(find.text(GroupMode.manual.label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(GroupMode.auto.label).last);
      await tester.pumpAndSettle();
      expect(key.currentState!.isDirty, isTrue);

      await tester.tap(find.text(GroupMode.auto.label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(GroupMode.manual.label).last);
      await tester.pumpAndSettle();
      expect(key.currentState!.isDirty, isFalse);
    });
  });
}
