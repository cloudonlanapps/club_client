// Issue 67: every form of cl_club_forms, turned off while one of its text
// inputs has the keyboard focus, takes no typing. The check itself is the
// harness's `expectKeyboardIgnoredWhenOff`.
//
// Issue 94: the same forms, turned off after they are mounted, draw every
// control off (`expectDrawnOffWhenTurnedOff`).
import 'dart:io';

import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/form_cases.dart';
import '../../support/form_harness.dart';

void main() {
  group('Issue 67: a form turned off takes no typing', () {
    test('Issue 67: every form of the package is among the forms tried', () {
      final mixedIn = RegExp(r'with\s+FormContract<(\w+)>');
      final forms = <String>{
        for (final file in Directory('lib/src/widgets').listSync(
          recursive: true,
        ))
          if (file is File && file.path.endsWith('.dart'))
            for (final match in mixedIn.allMatches(file.readAsStringSync()))
              match.group(1)!,
      };
      expect(forms, isNotEmpty);
      final tried = {for (final c in formCases) c.name.split(',').first};
      expect(forms.difference(tried), isEmpty, reason: 'forms not tried');
    });

    for (final c in formCases) {
      testWidgets('Issue 67: ${c.name} turned off takes no typing in the '
          'input that had the focus', (tester) async {
        final tried = await expectKeyboardIgnoredWhenOff(tester, c.build);
        if (c.typed) expect(tried, greaterThan(0), reason: 'inputs tried');
      });
    }

    testWidgets('Issue 67: a form that opens turned off gives its first '
        'input no focus', (tester) async {
      await pumpForm(tester, const LoginForm(enabled: false));

      expect(tester.testTextInput.hasAnyClients, isFalse);
      tester.testTextInput.enterText('typed while off');
      await tester.pumpAndSettle();
      final form = tester.state<ShadFormState>(find.byType(ShadForm));
      expect(form.value[LoginFormFields.usernameId], '');
    });
  });

  group('Issue 94: a form turned off after it is mounted is drawn off', () {
    for (final c in formCases) {
      testWidgets('Issue 94: ${c.name} turned off after it is mounted draws '
          'every control off, and on again when turned on', (tester) async {
        final checked = await expectDrawnOffWhenTurnedOff(tester, c.build);
        expect(checked, greaterThan(0), reason: 'controls checked');
      });
    }
  });
}
