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
            'hi': 'हमारे साथ खेलें',
            'mr': 'आमच्यासोबत खेळा',
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
            {'mr': 'क्लबसाठी एक प्रश्न'},
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
            {'hi': '12 उदाहरण मार्ग'},
          ),
          ClubAddressFormFields.cityId: FormTranslatedText('Pune', {
            'mr': 'पुणे',
          }),
          ClubAddressFormFields.stateId: FormTranslatedText('Maharashtra', {
            'mr': 'महाराष्ट्र',
          }),
          ClubAddressFormFields.postalCodeId: '411001',
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
