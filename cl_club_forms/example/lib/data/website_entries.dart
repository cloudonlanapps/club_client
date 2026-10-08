import 'package:cl_club_forms/cl_club_forms.dart';

import '../models/form_demo_entry.dart';
import '../models/form_demo_group.dart';
import 'inquiry_samples.dart';

/// The forms of the club's website.
abstract final class WebsiteEntries {
  /// The entries, in the order shown.
  static List<FormDemoEntry> get all => [
    FormDemoEntry(
      id: 'inquiry-contact',
      title: 'Inquiry form, contact',
      group: FormDemoGroup.website,
      formType: InquiryForm,
      builder: (key) => InquiryForm(
        key: key,
        copy: InquirySamples.contactCopy,
        choices: InquirySamples.contactChoices,
      ),
    ),
    FormDemoEntry(
      id: 'inquiry-interest',
      title: 'Inquiry form, interest',
      group: FormDemoGroup.website,
      formType: InquiryForm,
      builder: (key) => InquiryForm(
        key: key,
        copy: InquirySamples.interestCopy,
        choices: InquirySamples.interestChoices,
        messageRequired: false,
      ),
    ),
  ];
}
