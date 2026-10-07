import 'package:cl_club_forms/cl_club_forms.dart';

import '../models/form_demo_entry.dart';
import '../models/form_demo_group.dart';
import 'demo_samples.dart';

/// The forms of a member's credit packages.
abstract final class CreditEntries {
  /// The entries, in the order shown.
  static List<FormDemoEntry> get all => [
    FormDemoEntry(
      id: 'credit-grant',
      title: 'Credit grant form',
      group: FormDemoGroup.credit,
      formType: CreditGrantForm,
      builder: (key) => CreditGrantForm(
        key: key,
        programmes: DemoSamples.programmes,
        today: DemoSamples.today,
        initialValues: CreditGrantForm.defaultValues(today: DemoSamples.today),
      ),
    ),
    FormDemoEntry(
      id: 'credit-extend',
      title: 'Credit extend form',
      group: FormDemoGroup.credit,
      formType: CreditExtendForm,
      builder: (key) => CreditExtendForm(
        key: key,
        currentValidUntil: DemoSamples.inDays(DemoSamples.creditDays),
      ),
    ),
    FormDemoEntry(
      id: 'credit-reverse',
      title: 'Credit reverse form',
      group: FormDemoGroup.credit,
      formType: CreditReverseForm,
      builder: (key) =>
          CreditReverseForm(key: key, unspent: DemoSamples.creditBalance),
    ),
    FormDemoEntry(
      id: 'credit-transfer',
      title: 'Credit transfer form',
      group: FormDemoGroup.credit,
      formType: CreditTransferForm,
      builder: (key) => CreditTransferForm(
        key: key,
        balance: DemoSamples.creditBalance,
        today: DemoSamples.today,
      ),
    ),
  ];
}
