// Issue 389, ApplicationLibraryTextForm: one of the club's library texts —
// where it is used, a short name and its text in each catalogue language,
// `{fact}` gaps allowed; a term has a heading too.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/application/library/application_library_text_form_validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/account_user_form_harness.dart';
import '../../support/form_harness.dart';
import 'application_form_harness.dart';
import 'application_samples.dart';

const String _kind = ApplicationLibraryTextFormFields.kindId;
const String _name = ApplicationLibraryTextFormFields.nameId;
const String _heading = ApplicationLibraryTextFormFields.headingId;
const String _text = ApplicationLibraryTextFormFields.textId;

Future<ApplicationLibraryTextFormState> _pump(
  WidgetTester tester, {
  Map<String, dynamic> initialValues = const {},
}) async {
  final key = GlobalKey<ApplicationLibraryTextFormState>();
  await pumpForm(
    tester,
    ApplicationLibraryTextForm(
      key: key,
      initialValues: initialValues,
      languages: ApplicationSamples.languageOptions,
    ),
  );
  return key.currentState!;
}

void main() {
  group('Issue 389: ApplicationLibraryTextForm', () {
    testWidgets('Issue 389: a new text needs a kind, a name and a text; its '
        'gaps are kept as written', (tester) async {
      final state = await _pump(tester);
      expect(fieldIds(tester), [_kind, _name, _text]);
      expect(state.isDirty, isFalse);

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expect(find.text('Pick where the text is used'), findsOneWidget);
      expect(find.text('Give the text a name'), findsOneWidget);
      expect(find.text('Write the text in one language at least'), findsOne);

      await pickIn(tester, _kind, 0, 'Selection');
      await enterField(tester, _name, '  Attend the matches ');
      await typeIn(tester, _text, 0, 'I will play on {match_dates}.');
      await typeIn(tester, _text, 1, 'मी {match_dates} रोजी खेळेन.');

      expect(state.isDirty, isTrue);
      expect(state.validate(), {
        _kind: ApplicationClauseKind.selection,
        _name: 'Attend the matches',
        _heading: null,
        _text: {
          'en': 'I will play on {match_dates}.',
          'mr': 'मी {match_dates} रोजी खेळेन.',
        },
      });
    });

    testWidgets('Issue 389: a term shows its heading; another kind sends '
        'none', (tester) async {
      final state = await _pump(
        tester,
        initialValues: {
          _kind: ApplicationClauseKind.rule,
          _name: 'Matches',
          _heading: {'en': 'Matches'},
          _text: {'en': 'Matches run {match_dates}.'},
        },
      );
      expect(fieldIds(tester), [_kind, _name, _heading, _text]);
      expect(state.isDirty, isFalse);
      expect(state.validate()![_heading], {'en': 'Matches'});

      await pickIn(tester, _kind, 0, 'Note');
      expect(fieldIds(tester), [_kind, _name, _text]);
      expect(state.validate(), {
        _kind: ApplicationClauseKind.note,
        _name: 'Matches',
        _heading: null,
        _text: {'en': 'Matches run {match_dates}.'},
      });
    });

    testWidgets('Issue 389: a name over 100 characters is refused on its '
        'field', (tester) async {
      final state = await _pump(
        tester,
        initialValues: {
          _kind: ApplicationClauseKind.note,
          _text: {'en': 'A note.'},
        },
      );
      await enterField(tester, _name, 'n' * 101);
      // The input stops at 100; the check guards a seeded longer name.
      expect(state.validate()![_name], hasLength(100));
      expect(
        ApplicationLibraryTextFormValidators.name('n' * 101),
        'Keep the name to 100 characters',
      );
    });

    testWidgets('Issue 389: what the server refuses shows on the field it '
        'names', (tester) async {
      final state = await _pump(
        tester,
        initialValues: {
          _kind: ApplicationClauseKind.note,
          _name: 'Kit',
          _text: {'en': 'Bring kit.'},
        },
      );
      state.showErrors(fieldErrors: {_name: 'Taken'});
      await tester.pumpAndSettle();
      expect(messageOn(_name, 'Taken'), findsOneWidget);
    });
  });
}
