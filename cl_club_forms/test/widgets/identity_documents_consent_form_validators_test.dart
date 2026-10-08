import 'dart:io';

import 'package:cl_club_forms/src/widgets/identity_documents/identity_documents_consent_form_validators.dart';
import 'package:cl_club_forms/src/widgets/identity_documents/identity_documents_consent_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Issue 108: IdentityDocumentsConsentFormValidators', () {
    test('Issue 108: the consent must be given', () {
      expect(
        IdentityDocumentsConsentFormValidators.consent(false),
        IdentityDocumentsConsentStrings.required,
      );
      expect(
        IdentityDocumentsConsentStrings.required,
        'Please agree to the Privacy Policy to continue.',
      );
      expect(IdentityDocumentsConsentFormValidators.consent(true), null);
    });
  });

  test('Issue 108: neither the consent form nor a schedule cluster holds a '
      'rule in a closure', () {
    const files = [
      'identity_documents/identity_documents_consent_form.dart',
      'event_schedule/camp_schedule_fields.dart',
      'event_schedule/one_off_schedule_fields.dart',
      'event_schedule/programme_schedule_fields.dart',
    ];
    final closure = RegExp(r'validator:\s*\(');
    for (final file in files) {
      final source = File('lib/src/widgets/$file').readAsStringSync();
      expect(closure.hasMatch(source), isFalse, reason: file);
    }
  });
}
