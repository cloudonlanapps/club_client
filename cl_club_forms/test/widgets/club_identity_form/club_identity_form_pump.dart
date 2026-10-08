import 'package:cl_club_forms/src/widgets/club_identity_form/club_identity_text_input.dart';
import 'package:cl_club_forms/src/widgets/club_identity_form/translated_text_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/admin_forms_checks.dart';
import '../../support/form_harness.dart';

/// Mounts [form], one of the club identity section forms, bare.
Future<void> pumpClubIdentityForm(WidgetTester tester, Widget form) async {
  await tester.binding.setSurfaceSize(const Size(900, 3000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(body: SingleChildScrollView(child: form)),
    ),
  );
  await tester.pumpAndSettle();
}

/// The input registered under [id].
Finder clubIdentityInput(String id) =>
    find.byKey(ClubIdentityTextInput.keyOf(id));

/// The field id of [id]'s translation in [language].
String translationId(String id, String language) =>
    TranslatedTextInputs.translationIdOf(id, language);

/// Types [text] into the input registered under [id].
Future<void> enterClubIdentityText(
  WidgetTester tester,
  String id,
  String text,
) async {
  await tester.enterText(
    find.descendant(
      of: clubIdentityInput(id),
      matching: find.byType(EditableText),
    ),
    text,
  );
  await tester.pump();
}

/// What a fields-only form must not draw.
void expectNoCardAndNoButton() {
  expect(find.byType(ShadCard), findsNothing);
  expect(find.byType(Card), findsNothing);
  expect(find.byType(ShadButton), findsNothing);
  expect(find.byType(ShadIconButton), findsNothing);
}

/// A club identity form on screen, turned off as its host does while it
/// saves, shows every field off and none takes the pointer; turned on
/// again, every input takes the pointer. [build] gives the same form with
/// `enabled` on or off; [inputs] is how many inputs it shows.
Future<void> expectOffThenOnAgain(
  WidgetTester tester,
  Widget Function({required bool enabled}) build, {
  required int inputs,
}) async {
  final checked = await expectDrawnOffWhenTurnedOff(
    tester,
    build,
    whileOff: () => expectNoFieldResponds(tester),
  );
  expect(checked, inputs);

  final texts = find.byType(EditableText);
  expect(texts, findsNWidgets(inputs));
  for (var i = 0; i < inputs; i++) {
    await tester.tap(texts.at(i));
    await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(texts.at(i)).focusNode.hasFocus,
      isTrue,
      reason: 'input $i took no pointer',
    );
  }
}
