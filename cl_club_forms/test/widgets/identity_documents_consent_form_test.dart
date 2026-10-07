import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/identity_documents/identity_documents_consent_form_fields.dart'
    show IdentityDocumentsConsentFormFields;
import 'package:cl_club_forms/src/widgets/identity_documents/identity_documents_consent_strings.dart'
    show IdentityDocumentsConsentStrings;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/admin_forms_checks.dart';
import '../support/form_harness.dart';

// Against the list of club_client#61: IdentityDocumentsConsentForm is one
// checkbox, labelled by its own inline text (which carries the policy link)
// and not by a LabeledFormRow. It has no rule across fields and nothing to
// type. It does not mix in FormContract: it offers validate() and isDirty
// (true while the box is ticked) but no showErrors(), so the server-errors
// point does not apply. Its only in-form action is the Privacy Policy link,
// which opens IdentityDocumentsPrivacyPolicyDialog; the dialog's Close is
// the dialog's own button.

Future<GlobalKey<IdentityDocumentsConsentFormState>> _pump(
  WidgetTester tester, {
  bool enabled = true,
}) async {
  final key = GlobalKey<IdentityDocumentsConsentFormState>();
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(
        body: IdentityDocumentsConsentForm(key: key, enabled: enabled),
      ),
    ),
  );
  return key;
}

Future<void> _tick(WidgetTester tester) async {
  tester.widget<ShadCheckbox>(find.byType(ShadCheckbox)).onChanged?.call(true);
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 51: IdentityDocumentsConsentForm', () {
    testWidgets('Issue 51: it holds the checkbox and no button', (
      tester,
    ) async {
      await _pump(tester);
      expect(find.byType(ShadCheckboxFormField), findsOneWidget);
      expect(find.byType(ShadButton), findsNothing);
    });

    testWidgets('Issue 51: validate refuses an unticked box, with a message', (
      tester,
    ) async {
      final key = await _pump(tester);
      expect(key.currentState!.isDirty, isFalse);
      expect(key.currentState!.validate(), isNull);
      await tester.pumpAndSettle();
      expect(find.text(IdentityDocumentsConsentStrings.required), findsOne);
    });

    testWidgets('Issue 51: validate returns the consent once ticked', (
      tester,
    ) async {
      final key = await _pump(tester);
      await _tick(tester);
      expect(key.currentState!.isDirty, isTrue);
      expect(key.currentState!.validate(), {
        IdentityDocumentsConsentFormFields.privacyAcceptedId: true,
      });
      await tester.pumpAndSettle();
      expect(find.text(IdentityDocumentsConsentStrings.required), findsNothing);
    });

    testWidgets('Issue 51: the link in the label opens the privacy policy', (
      tester,
    ) async {
      final key = await _pump(tester);
      key.currentState!.openPolicy();
      await tester.pumpAndSettle();
      expect(find.text('How we handle your Aadhaar'), findsOneWidget);
    });

    testWidgets('Issue 51: disabled, the link opens nothing', (tester) async {
      final key = await _pump(tester, enabled: false);
      key.currentState!.openPolicy();
      await tester.pumpAndSettle();
      expect(find.text('How we handle your Aadhaar'), findsNothing);
    });
  });

  group('Issue 61: IdentityDocumentsConsentForm', () {
    const id = IdentityDocumentsConsentFormFields.privacyAcceptedId;
    const policyTitle = 'How we handle your Aadhaar';

    Future<IdentityDocumentsConsentFormState> pump(
      WidgetTester tester, {
      bool enabled = true,
    }) async {
      final key = GlobalKey<IdentityDocumentsConsentFormState>();
      await pumpForm(
        tester,
        IdentityDocumentsConsentForm(key: key, enabled: enabled),
      );
      return key.currentState!;
    }

    /// Taps where the link sits in the consent line: three quarters along
    /// it, the link being its second half. A disabled form ignores pointers,
    /// so the tap is by position, not through the text's hit test.
    Future<void> tapLink(WidgetTester tester) async {
      final line = tester.getRect(
        find.text('I agree to the Privacy Policy.', findRichText: true),
      );
      await tester.tapAt(line.centerLeft + Offset(line.width * 0.75, 0));
      await tester.pumpAndSettle();
    }

    testWidgets('Issue 61: it shows one unticked checkbox, labelled with '
        'the consent line', (tester) async {
      await pump(tester);

      expect(formOf(tester).fields.keys, [id]);
      expect(
        find.descendant(
          of: fieldWithId(id),
          matching: find.text(
            'I agree to the Privacy Policy.',
            findRichText: true,
          ),
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<ShadCheckbox>(find.byType(ShadCheckbox)).value,
        false,
      );
      expectNoHostChrome(tester);
    });

    testWidgets('Issue 61: unticked, validate refuses with the message on '
        'the checkbox', (tester) async {
      final state = await pump(tester);

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expectFieldError(id, IdentityDocumentsConsentStrings.required);
    });

    testWidgets('Issue 61: a tap on the box ticks it, and validate then '
        'returns exactly the consent', (tester) async {
      final state = await pump(tester);

      await tester.tap(find.byType(ShadCheckbox));
      await tester.pumpAndSettle();

      final values = state.validate();
      expect(values, {id: true});
      expect(values![id], isA<bool>());
    });

    testWidgets('Issue 61: ticking the box takes the message away', (
      tester,
    ) async {
      final state = await pump(tester);
      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expect(find.text(IdentityDocumentsConsentStrings.required), findsOne);

      await tester.tap(find.byType(ShadCheckbox));
      await tester.pumpAndSettle();

      expect(find.text(IdentityDocumentsConsentStrings.required), findsNothing);
    });

    testWidgets('Issue 61: isDirty follows the box: false, true once '
        'ticked, false again once unticked, when validate refuses again', (
      tester,
    ) async {
      final state = await pump(tester);
      expect(state.isDirty, isFalse);

      await tester.tap(find.byType(ShadCheckbox));
      await tester.pumpAndSettle();
      expect(state.isDirty, isTrue);

      await tester.tap(find.byType(ShadCheckbox));
      await tester.pumpAndSettle();
      expect(state.isDirty, isFalse);
      expect(state.validate(), isNull);
    });

    testWidgets('Issue 61: a tap on the Privacy Policy link opens the '
        'policy and leaves the box as it was', (tester) async {
      final state = await pump(tester);

      await tapLink(tester);

      expect(find.text(policyTitle), findsOneWidget);
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: the policy says what the documents are used '
        'for, and Close takes it away', (tester) async {
      final state = await pump(tester);
      await tester.tap(find.byType(ShadCheckbox));
      await tapLink(tester);

      for (final part in [
        'We only use your Aadhaar to confirm your name and date of birth',
        'We will never use it for marketing',
        'Only authorised reviewers can see your files',
      ]) {
        expect(find.textContaining(part), findsOneWidget, reason: part);
      }

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text(policyTitle), findsNothing);
      expect(find.byType(IdentityDocumentsConsentForm), findsOneWidget);
      expect(state.validate(), {id: true});
    });

    testWidgets('Issue 61: with enabled false neither the box nor the link '
        'responds', (tester) async {
      final state = await pump(tester, enabled: false);

      await expectNoFieldResponds(tester);
      await tester.tap(find.byType(ShadCheckbox), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(state.isDirty, isFalse);

      await tapLink(tester);
      expect(find.text(policyTitle), findsNothing);
    });

    testWidgets('Issue 61: it fits a phone', (tester) async {
      await expectFitsPhone(tester, const IdentityDocumentsConsentForm());
    });

    testWidgets('Issue 61: the policy fits a phone', (tester) async {
      final key = GlobalKey<IdentityDocumentsConsentFormState>();
      await pumpForm(
        tester,
        IdentityDocumentsConsentForm(key: key),
        size: kPhoneSurface,
      );

      // At this width the consent line wraps, so the link is opened as the
      // tap on it does.
      key.currentState!.policyTap.onTap!();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(policyTitle), findsOneWidget);
      expect(
        tester.getSize(find.byType(ShadDialog)).width,
        lessThanOrEqualTo(kPhoneSurface.width),
      );
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text(policyTitle), findsNothing);
    });
  });
}
