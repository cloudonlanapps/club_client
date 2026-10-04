import 'package:cl_club_credits/src/models/credit_form_helpers.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show clCreditAccountsMasterProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart' show CreditFormFields;

import 'support/credit_test_scope.dart';

Map<String, dynamic> _grant({required int programme, bool trial = false}) => {
  CreditFormFields.creditsId: 3,
  CreditFormFields.validFromId: DateTime(2026, 9, 26),
  CreditFormFields.validUntilId: DateTime(2026, 12, 25),
  CreditFormFields.programmeId: programme,
  CreditFormFields.trialId: trial,
  CreditFormFields.reasonId: 'gift',
};

void main() {
  group('Issue 101: the credit form adapter', () {
    test('Issue 101: a validity window spans whole local days', () {
      final day = DateTime(2026, 9, 26);
      expect(creditValidFromUtc(day), DateTime(2026, 9, 26).toUtc());
      expect(
        creditValidUntilUtc(day),
        DateTime(2026, 9, 26, 23, 59, 59).toUtc(),
      );
    });

    test('Issue 101: General opens an unbound account; a programme binds '
        'it', () async {
      final stub = StubAccounts(const {});
      final container = ProviderContainer(
        overrides: [clCreditAccountsMasterProvider.overrideWith(() => stub)],
      );
      addTearDown(container.dispose);
      final sub = container.listen(
        clCreditAccountsMasterProvider('adapter_member'),
        (_, _) {},
      );
      addTearDown(sub.close);
      final notifier = container.read(
        clCreditAccountsMasterProvider('adapter_member').notifier,
      );

      await CreditAccountFormSubmit.openAccount(
        values: _grant(programme: CreditFormFields.generalProgramme),
        notifier: notifier,
      );
      await CreditAccountFormSubmit.openAccount(
        values: _grant(programme: 9, trial: true),
        notifier: notifier,
      );

      expect(stub.opened, [
        'adapter_member 3 null false gift',
        'adapter_member 3 9 true gift',
      ]);
    });
  });
}
