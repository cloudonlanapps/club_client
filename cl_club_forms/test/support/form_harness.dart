import 'package:cl_club_forms/src/widgets/form/form_contract.dart';
import 'package:cl_club_forms/src/widgets/form/labeled_form_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

export 'form_refusal_harness.dart';

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
  // Fields mounted on their own, outside a form, have nothing to keep the
  // focus off them.
  if (tester.allStates.any((state) => state is FormContract)) {
    expectNoInputOffHasFocus(tester);
  }
}

/// The text inputs on screen, in order.
final Finder _textInputs = find.byType(EditableText);

/// No text input that is turned off has the keyboard focus, so none takes
/// typing. [pumpForm] checks it on every form it mounts, which covers a
/// form that opens turned off with a field that asks for the focus.
void expectNoInputOffHasFocus(WidgetTester tester) {
  for (final input in tester.widgetList<ShadInput>(find.byType(ShadInput))) {
    if (input.enabled) continue;
    final texts = tester.widgetList<EditableText>(
      find.descendant(of: find.byWidget(input), matching: _textInputs),
    );
    expect(
      texts.where((text) => text.focusNode.hasFocus),
      isEmpty,
      reason: 'a text input that is off has the keyboard focus',
    );
  }
}

/// The keyboard check of a form: a text input that has the focus when the
/// form is turned off takes no typing. [build] gives the same form with
/// `enabled` on or off, as a host rebuilds it while it saves.
///
/// Every text input the form shows is tried in turn: it takes the focus,
/// the form is turned off, and the keyboard types. The input must have lost
/// the focus and the form's values must be as they were. Returns how many
/// inputs were tried.
Future<int> expectKeyboardIgnoredWhenOff(
  WidgetTester tester,
  Widget Function({required bool enabled}) build, {
  Size size = kFormSurface,
}) async {
  await pumpForm(tester, build(enabled: true), size: size);
  final count = _textInputs.evaluate().length;
  var tried = 0;
  for (var i = 0; i < count; i++) {
    await pumpForm(tester, build(enabled: true), size: size);
    if (i >= _textInputs.evaluate().length) break;
    await tester.showKeyboard(_textInputs.at(i));
    await tester.pumpAndSettle();
    final focus = tester.widget<EditableText>(_textInputs.at(i)).focusNode;
    // A read-only input takes no focus to begin with.
    if (!focus.hasFocus) continue;
    tried++;

    final form = tester.state<ShadFormState>(find.byType(ShadForm).first);
    final before = Map<String, dynamic>.of(form.value);
    await pumpForm(tester, build(enabled: false), size: size);
    expect(focus.hasFocus, isFalse, reason: 'input $i kept the focus');

    tester.testTextInput.enterText('typed while off');
    await tester.pumpAndSettle();
    expect(form.value, before, reason: 'typing changed input $i');
  }
  return tried;
}

/// The controls on screen that have an on and an off look, each with
/// whether it is drawn on. A control kept offstage has no look and is left
/// out.
List<bool> drawnControls(WidgetTester tester) => [
  for (final widget in tester.widgetList(
    find.byWidgetPredicate((w) => _drawnOn(w) != null),
  ))
    _drawnOn(widget)!,
];

/// Whether [widget], a control, is drawn on; null when it is no control.
bool? _drawnOn(Widget widget) => switch (widget) {
  ShadInput(:final enabled) => enabled,
  ShadSelect<dynamic>(:final enabled) => enabled,
  ShadCheckbox(:final enabled) => enabled,
  ShadSwitch(:final enabled) => enabled,
  ShadRadioGroup<dynamic>(:final enabled) => enabled,
  ShadButton(:final enabled) => enabled,
  _ => null,
};

/// The look of a form turned off after it is mounted, as a host does while
/// it saves: every control is drawn off, and turned on again each is drawn
/// as it was. [build] gives the same form with `enabled` on or off.
///
/// Only the form is built again when it is turned off, as under a host's
/// `setState`: nothing above it changes, so a field the form does not build
/// again keeps the look it had. (A second [pumpForm] builds the whole app
/// again, theme included, which redraws every field and hides that.)
/// [whileOff] runs while the form is off, for what a test checks then.
/// Returns how many controls were checked.
Future<int> expectDrawnOffWhenTurnedOff(
  WidgetTester tester,
  Widget Function({required bool enabled}) build, {
  Size size = kFormSurface,
  Future<void> Function()? whileOff,
}) async {
  final enabled = ValueNotifier<bool>(true);
  addTearDown(enabled.dispose);
  await pumpForm(
    tester,
    ValueListenableBuilder<bool>(
      valueListenable: enabled,
      builder: (context, on, _) => build(enabled: on),
    ),
    size: size,
  );
  final before = drawnControls(tester);

  enabled.value = false;
  await tester.pumpAndSettle();
  final off = drawnControls(tester);
  expect(off, hasLength(before.length));
  expect(
    [
      for (var i = 0; i < off.length; i++)
        if (off[i]) i,
    ],
    isEmpty,
    reason: 'controls still drawn on',
  );
  await whileOff?.call();

  enabled.value = true;
  await tester.pumpAndSettle();
  expect(drawnControls(tester), before, reason: 'controls turned on again');
  return before.length;
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
/// in-form actions (Clear, Transfer, ...).
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
