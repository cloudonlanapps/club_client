import 'package:cl_club_forms/cl_club_forms.dart';

import '../models/form_demo_entry.dart';
import '../models/form_demo_group.dart';
import 'demo_samples.dart';

/// The forms of the club's own details.
abstract final class ClubIdentityEntries {
  /// The entries, in the order shown.
  static List<FormDemoEntry> get all => [
    FormDemoEntry(
      id: 'club-details',
      title: 'Club details form',
      group: FormDemoGroup.clubIdentity,
      formType: ClubDetailsForm,
      builder: (key) => ClubDetailsForm(
        key: key,
        languages: DemoSamples.languages,
        initialValues: const {
          ClubDetailsFormFields.nameId: 'Example Sports Club',
          ClubDetailsFormFields.shortNameId: 'ESC',
          ClubDetailsFormFields.taglineId: FormTranslatedText('Play with us', {
            'fr': 'Jouez avec nous',
          }),
          ClubDetailsFormFields.inquiryEmailId: 'hello@example.test',
        },
      ),
    ),
    FormDemoEntry(
      id: 'club-contact',
      title: 'Club contact form',
      group: FormDemoGroup.clubIdentity,
      formType: ClubContactForm,
      builder: (key) => ClubContactForm(
        key: key,
        languages: DemoSamples.languages,
        initialValues: const {
          ClubContactFormFields.phoneNumberId: '+10000000000',
          ClubContactFormFields.emailId: 'hello@example.test',
          ClubContactFormFields.emailSubjectId: FormTranslatedText(
            'A question for the club',
            {'es': 'Una pregunta para el club'},
          ),
          ClubContactFormFields.instagramUrlId:
              'https://social.example.test/example-sports-club',
        },
      ),
    ),
    FormDemoEntry(
      id: 'club-address',
      title: 'Club address form',
      group: FormDemoGroup.clubIdentity,
      formType: ClubAddressForm,
      builder: (key) => ClubAddressForm(
        key: key,
        languages: DemoSamples.languages,
        initialValues: const {
          ClubAddressFormFields.addressId: FormTranslatedText(
            '12 Example Street',
            {'fr': '12 rue Exemple'},
          ),
          ClubAddressFormFields.cityId: FormTranslatedText('Sampletown'),
          ClubAddressFormFields.postalCodeId: '000000',
        },
      ),
    ),
    FormDemoEntry(
      id: 'club-language',
      title: 'Club language form',
      group: FormDemoGroup.clubIdentity,
      formType: ClubLanguageForm,
      builder: (key) =>
          ClubLanguageForm(key: key, languages: DemoSamples.languages),
    ),
  ];
}
