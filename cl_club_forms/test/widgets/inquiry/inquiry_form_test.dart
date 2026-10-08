import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/inquiry/inquiry_honeypot_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/form_harness.dart';

const _nameRequired = 'A name is needed.';
const _emailRequired = 'An email is needed.';
const _emailInvalid = 'Not an email address.';
const _messageRequired = 'A message is needed.';

const _copy = InquiryFormCopy(
  nameLabel: 'Name',
  namePlaceholder: 'Your full name',
  emailLabel: 'Email',
  emailPlaceholder: 'you@example.test',
  phoneLabel: 'Phone',
  phonePlaceholder: '99999 99999',
  messageLabel: 'Message',
  messagePlaceholder: 'Your message',
  nameRequired: _nameRequired,
  emailRequired: _emailRequired,
  emailInvalid: _emailInvalid,
  messageRequired: _messageRequired,
);

const _choices = [
  InquiryChoice(
    key: 'ageGroup',
    label: 'Age group',
    placeholder: 'Select an age group',
    options: {'child': 'Child', 'adult': 'Adult'},
  ),
  InquiryChoice(
    key: 'programme',
    label: 'Interested in',
    placeholder: 'Select a programme',
    options: {'camps': 'Camps', 'training': 'Training'},
  ),
];

Widget _form(
  GlobalKey<InquiryFormState>? key, {
  List<InquiryChoice> choices = const [],
  bool messageRequired = true,
  bool enabled = true,
}) => InquiryForm(
  key: key,
  copy: _copy,
  choices: choices,
  messageRequired: messageRequired,
  enabled: enabled,
);

Future<GlobalKey<InquiryFormState>> _pump(
  WidgetTester tester, {
  List<InquiryChoice> choices = const [],
  bool messageRequired = true,
  bool enabled = true,
}) async {
  final key = GlobalKey<InquiryFormState>();
  await pumpForm(
    tester,
    _form(
      key,
      choices: choices,
      messageRequired: messageRequired,
      enabled: enabled,
    ),
  );
  return key;
}

/// [message], shown on the field with [id] and nowhere else.
void _expectOnField(String id, String message) {
  expect(find.text(message), findsOneWidget);
  expect(
    find.descendant(of: fieldWithId(id), matching: find.text(message)),
    findsOneWidget,
  );
}

Finder _honeypot() => find.byType(InquiryHoneypotField);

void main() {
  testWidgets('Issue 84: InquiryForm has fields only, each in a labelled '
      'row, the required ones marked', (tester) async {
    await _pump(tester, choices: _choices);

    expect(rowLabels(tester), [
      'Name *',
      'Email *',
      'Phone',
      'Age group',
      'Interested in',
      'Message *',
    ]);
    expectLabelsAreRows(tester);
    expectNoHostChrome(tester);
    expect(find.text('Your full name'), findsOneWidget);
    expect(find.text('Select an age group'), findsOneWidget);
  });

  testWidgets('Issue 84: an optional message is not marked required', (
    tester,
  ) async {
    await _pump(tester, messageRequired: false);

    expect(rowLabels(tester), ['Name *', 'Email *', 'Phone', 'Message']);
  });

  testWidgets('Issue 84: a missing name, email and required message each '
      'show on their own field', (tester) async {
    final key = await _pump(tester);

    expect(key.currentState!.validate(), isNull);
    await tester.pumpAndSettle();

    _expectOnField(InquiryFormFields.nameId, _nameRequired);
    _expectOnField(InquiryFormFields.emailId, _emailRequired);
    _expectOnField(InquiryFormFields.messageId, _messageRequired);
  });

  testWidgets('Issue 84: a malformed email shows on the email field alone', (
    tester,
  ) async {
    final key = await _pump(tester);
    await enterField(tester, InquiryFormFields.nameId, 'Robin Example');
    await enterField(tester, InquiryFormFields.emailId, 'robin-at-example');
    await enterField(tester, InquiryFormFields.messageId, 'Hello');

    expect(key.currentState!.validate(), isNull);
    await tester.pumpAndSettle();

    _expectOnField(InquiryFormFields.emailId, _emailInvalid);
    expect(find.text(_nameRequired), findsNothing);
    expect(find.text(_messageRequired), findsNothing);
  });

  testWidgets('Issue 84: validate returns the trimmed texts, no answers and '
      'an empty honeypot', (tester) async {
    final key = await _pump(tester, choices: _choices);
    await enterField(tester, InquiryFormFields.nameId, '  Robin Example ');
    await enterField(tester, InquiryFormFields.emailId, ' robin@example.test ');
    await enterField(tester, InquiryFormFields.phoneId, ' 98765 43210 ');
    await enterField(tester, InquiryFormFields.messageId, ' Hello ');

    expect(key.currentState!.validate(), {
      InquiryFormFields.nameId: 'Robin Example',
      InquiryFormFields.emailId: 'robin@example.test',
      InquiryFormFields.phoneId: '98765 43210',
      InquiryFormFields.messageId: 'Hello',
      InquiryFormFields.answersId: <String, String>{},
      InquiryFormFields.honeypotId: '',
    });
  });

  testWidgets('Issue 84: an interest form is valid without a phone or a '
      'message, and returns the questions answered by key', (tester) async {
    final key = await _pump(tester, choices: _choices, messageRequired: false);
    await enterField(tester, InquiryFormFields.nameId, 'Robin Example');
    await enterField(tester, InquiryFormFields.emailId, 'robin@example.test');

    await tester.tap(find.text('Select an age group'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adult').last);
    await tester.pumpAndSettle();
    expect(find.text('Adult'), findsOneWidget);

    final values = key.currentState!.validate();
    expect(values, isNotNull);
    expect(values![InquiryFormFields.phoneId], '');
    expect(values[InquiryFormFields.messageId], '');
    expect(values[InquiryFormFields.answersId], {'ageGroup': 'adult'});
  });

  testWidgets('Issue 84: the honeypot takes no room and is out of the tab '
      'order and the semantics tree', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);

    expect(_honeypot(), findsOneWidget);
    // Its field is built, and offstage.
    expect(fieldWithId(InquiryFormFields.honeypotId), findsNothing);
    expect(
      find.byWidgetPredicate(
        (w) => w is ShadInputFormField && w.id == InquiryFormFields.honeypotId,
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(tester.getSize(_honeypot()), const Size(992, 0));

    final input = find.descendant(
      of: _honeypot(),
      matching: find.byType(EditableText, skipOffstage: false),
      skipOffstage: false,
    );
    expect(input, findsOneWidget);
    expect(tester.widget<EditableText>(input).focusNode.canRequestFocus, false);
    expect(
      find.ancestor(of: input, matching: find.byType(ExcludeSemantics)),
      findsWidgets,
    );

    // Tab walks the four fields a person sees and comes back to the first.
    final visited = <FocusNode>{};
    for (var i = 0; i < 6; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      visited.add(FocusManager.instance.primaryFocus!);
    }
    expect(visited, hasLength(4));
    expect(
      visited,
      isNot(contains(tester.widget<EditableText>(input).focusNode)),
    );

    // What a screen reader is offered: the four fields, no fifth.
    expect(
      find.semantics.byFlag(SemanticsFlag.isTextField).evaluate(),
      hasLength(4),
    );
    semantics.dispose();
  });

  testWidgets('Issue 84: what fills the honeypot comes back from validate', (
    tester,
  ) async {
    final key = await _pump(tester);
    await enterField(tester, InquiryFormFields.nameId, 'Robin Example');
    await enterField(tester, InquiryFormFields.emailId, 'robin@example.test');
    await enterField(tester, InquiryFormFields.messageId, 'Hello');
    await setField(
      tester,
      key.currentState!,
      InquiryFormFields.honeypotId,
      'https://spam.example.test',
    );

    expect(
      key.currentState!.validate()![InquiryFormFields.honeypotId],
      'https://spam.example.test',
    );
  });

  testWidgets('Issue 84: isDirty follows the fields', (tester) async {
    final key = await _pump(tester);
    expect(key.currentState!.isDirty, isFalse);

    await enterField(tester, InquiryFormFields.nameId, 'Robin');
    expect(key.currentState!.isDirty, isTrue);
  });

  testWidgets('Issue 84: showErrors puts a refusal on its field and inline', (
    tester,
  ) async {
    final key = await _pump(tester);

    await expectShowsServerErrors(
      tester,
      key.currentState!,
      InquiryFormFields.emailId,
    );
  });

  testWidgets('Issue 84: InquiryForm with enabled off takes no input', (
    tester,
  ) async {
    await _pump(tester, choices: _choices, enabled: false);

    final inputs = tester.widgetList<ShadInput>(find.byType(ShadInput));
    expect(inputs, hasLength(4));
    expect(inputs.every((input) => !input.enabled), isTrue);
    final selects = tester.widgetList<ShadSelect<String>>(
      find.byType(ShadSelect<String>),
    );
    expect(selects, hasLength(2));
    expect(selects.every((select) => !select.enabled), isTrue);
  });

  testWidgets('Issue 84: InquiryForm fits a phone', (tester) async {
    await expectFitsPhone(tester, _form(null, choices: _choices));
  });
}
