import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/identity_documents/identity_documents_consent_form_fields.dart'
    show IdentityDocumentsConsentFormFields;
import 'package:cl_club_forms/src/widgets/identity_documents/identity_documents_consent_strings.dart'
    show IdentityDocumentsConsentStrings;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

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
}
