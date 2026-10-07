import 'package:cl_club_forms/src/widgets/form/form_contract.dart';
import 'package:cl_club_forms/src/widgets/form/labeled_form_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// A surface tall enough that no form scrolls its fields out of reach.
const Size kFormSurface = Size(1024, 2400);

/// A phone, portrait.
const Size kPhoneSurface = Size(390, 844);

/// Mounts [form] alone, as a host would, on a surface of [size].
Future<void> pumpForm(
  WidgetTester tester,
  Widget form, {
  Size size = kFormSurface,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: form,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The labels of the form's rows, top to bottom, as shown: a required row's
/// label ends in ` *`.
List<String> rowLabels(WidgetTester tester) => [
  for (final row in tester.widgetList<LabeledFormRow>(
    find.byType(LabeledFormRow),
  ))
    if (row.label != null && row.required)
      '${row.label} *'
    else if (row.label != null)
      row.label!,
];

/// The field with [id], found by the id every shadcn form field carries.
Finder fieldWithId(String id) => find.byWidgetPredicate(
  (widget) => widget is ShadFormBuilderField && widget.id == id,
  description: 'form field "$id"',
);

/// Types [text] into the text field with [id].
Future<void> enterField(WidgetTester tester, String id, String text) async {
  await tester.enterText(
    find.descendant(of: fieldWithId(id), matching: find.byType(EditableText)),
    text,
  );
  await tester.pumpAndSettle();
}

/// Sets the field with [id] to [value] through the form, for fields a test
/// cannot type into (selects, pickers, switches, custom fields).
Future<void> setField(
  WidgetTester tester,
  FormContract state,
  String id,
  Object? value,
) async {
  state.formKey.currentState!.setFieldValue(id, value);
  await tester.pumpAndSettle();
}

/// No field of the form has its own `label:`; every label is a row's.
void expectLabelsAreRows(WidgetTester tester) {
  final own = [
    for (final field in tester.widgetList<ShadFormBuilderField<dynamic>>(
      find.byWidgetPredicate((w) => w is ShadFormBuilderField),
    ))
      if (field.label != null) field.id,
  ];
  expect(own, isEmpty, reason: 'fields labelled by themselves');
}

/// The form draws no button that submits and no heading of its own: a
/// [ShadButton] inside the form must be one of [allowedButtonTexts], the
/// in-form actions (Reset, Transfer, ...).
void expectNoHostChrome(
  WidgetTester tester, {
  Set<String> allowedButtonTexts = const {},
}) {
  final texts = <String>[];
  for (final button in find.byType(ShadButton).evaluate()) {
    final label = find.descendant(
      of: find.byWidget(button.widget),
      matching: find.byType(Text),
    );
    for (final text in label.evaluate()) {
      texts.add((text.widget as Text).data ?? '');
    }
  }
  expect(
    texts.where((text) => !allowedButtonTexts.contains(text)),
    isEmpty,
    reason: 'buttons the host should own',
  );
}

/// The standard checks of `showErrors` on [state]: the message of
/// [fieldId] shows on that field, the form-level one inline, and the next
/// `showErrors()` takes the form-level one away.
Future<void> expectShowsServerErrors(
  WidgetTester tester,
  FormContract state,
  String fieldId,
) async {
  const onField = 'Refused by the server.';
  const onForm = 'Could not save.';
  state.showErrors(fieldErrors: const {}, formError: onForm);
  await tester.pumpAndSettle();
  expect(find.text(onForm), findsOneWidget);

  state.showErrors(fieldErrors: {fieldId: onField});
  await tester.pumpAndSettle();
  expect(
    find.descendant(of: fieldWithId(fieldId), matching: find.text(onField)),
    findsOneWidget,
  );
  expect(find.text(onForm), findsNothing);

  state.showErrors();
  await tester.pumpAndSettle();
  expect(find.text(onField), findsNothing);
}

/// Mounting [form] at phone width overflows nothing.
Future<void> expectFitsPhone(WidgetTester tester, Widget form) async {
  await pumpForm(tester, form, size: kPhoneSurface);
  expect(tester.takeException(), isNull);
}
