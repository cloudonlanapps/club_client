import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'club_identity_form_pump.dart';

typedef _F = ClubLanguageFormFields;

Future<GlobalKey<ClubLanguageFormState>> _pump(
  WidgetTester tester, {
  List<String> languages = const ['mr'],
  VoidCallback? onSubmitted,
}) async {
  final key = GlobalKey<ClubLanguageFormState>();
  await pumpClubIdentityForm(
    tester,
    ClubLanguageForm(
      key: key,
      languages: languages,
      onSubmitted: onSubmitted,
    ),
  );
  return key;
}

Finder get _input => find.descendant(
  of: find.byKey(_F.languageCodeKey),
  matching: find.byType(EditableText),
);

Future<void> _enter(WidgetTester tester, String text) async {
  await tester.enterText(_input, text);
  await tester.pump();
}

void main() {
  group('Issue 58: ClubLanguageForm', () {
    testWidgets('Issue 58: ClubLanguageForm has one labelled field, no card '
        'and no button', (tester) async {
      await _pump(tester);

      expect(find.byType(EditableText), findsOneWidget);
      expect(find.text(_F.languageCodeLabel), findsOneWidget);
      expect(find.text(_F.languageCodePlaceholder), findsOneWidget);
      expect(
        find.byKey(const ValueKey('clubIdentity.addLanguage')),
        findsOneWidget,
      );
      expectNoCardAndNoButton();
    });

    testWidgets('Issue 58: ClubLanguageForm accepts a valid code and '
        'returns it trimmed', (tester) async {
      final key = await _pump(tester);
      expect(key.currentState!.isDirty, isFalse);

      await _enter(tester, ' hi ');

      expect(key.currentState!.isDirty, isTrue);
      expect(key.currentState!.validate(), {_F.languageCodeId: 'hi'});
    });

    testWidgets('Issue 58: ClubLanguageForm refuses an invalid code, and an '
        'empty one, on the field', (tester) async {
      final key = await _pump(tester);

      expect(key.currentState!.validate(), isNull);
      await tester.pump();
      expect(find.textContaining('two- or three-letter'), findsOneWidget);

      await _enter(tester, 'Marathi');
      expect(key.currentState!.validate(), isNull);
      await tester.pump();
      expect(find.textContaining('two- or three-letter'), findsOneWidget);
    });

    testWidgets('Issue 58: ClubLanguageForm refuses a code that is already '
        'listed', (tester) async {
      final key = await _pump(tester);

      await _enter(tester, 'mr');

      expect(key.currentState!.validate(), isNull);
      await tester.pump();
      expect(find.text('mr is already offered'), findsOneWidget);
    });

    testWidgets('Issue 58: ClubLanguageForm reset empties the field and its '
        'message', (tester) async {
      final key = await _pump(tester);

      await _enter(tester, 'mr');
      expect(key.currentState!.validate(), isNull);
      await tester.pump();

      key.currentState!.reset();
      await tester.pump();

      expect(find.text('mr'), findsNothing);
      expect(find.text('mr is already offered'), findsNothing);
      expect(key.currentState!.isDirty, isFalse);
    });

    testWidgets('Issue 58: ClubLanguageForm hands Enter to the host', (
      tester,
    ) async {
      var submitted = 0;
      await _pump(tester, onSubmitted: () => submitted++);

      await _enter(tester, 'hi');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(submitted, 1);
    });
  });
}
