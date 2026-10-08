import 'package:cl_club_forms/cl_club_forms.dart';

/// Made-up wording and questions the inquiry form is mounted with, standing
/// in for what a website reads from its club's copy.
abstract final class InquirySamples {
  /// The wording of the contact form.
  static const InquiryFormCopy contactCopy = InquiryFormCopy(
    nameLabel: 'Name',
    namePlaceholder: 'Your full name',
    emailLabel: 'Email',
    emailPlaceholder: 'you@example.test',
    phoneLabel: 'Phone',
    phonePlaceholder: '99999 99999',
    messageLabel: 'Message',
    messagePlaceholder: 'How can we help you?',
    nameRequired: 'Please tell us your name.',
    emailRequired: 'Please give an email we can reply to.',
    emailInvalid: 'That does not look like an email address.',
    messageRequired: 'Please write a message.',
  );

  /// The wording of the interest form: the contact form's, with a note in
  /// place of the message.
  static const InquiryFormCopy interestCopy = InquiryFormCopy(
    nameLabel: 'Name',
    namePlaceholder: 'Your full name',
    emailLabel: 'Email',
    emailPlaceholder: 'you@example.test',
    phoneLabel: 'Phone',
    phonePlaceholder: '99999 99999',
    messageLabel: 'Anything else we should know',
    messagePlaceholder: 'Experience, questions, preferred days',
    nameRequired: 'Please tell us your name.',
    emailRequired: 'Please give an email we can reply to.',
    emailInvalid: 'That does not look like an email address.',
    messageRequired: 'Please write a note.',
  );

  /// The question of the contact form.
  static const List<InquiryChoice> contactChoices = [
    InquiryChoice(
      key: 'subject',
      label: 'Subject',
      placeholder: 'Select a topic',
      options: {
        'registration': 'Registration',
        'programs': 'Programmes',
        'other': 'Other',
      },
    ),
  ];

  /// The questions of the interest form.
  static const List<InquiryChoice> interestChoices = [
    InquiryChoice(
      key: 'ageGroup',
      label: 'Age group',
      placeholder: 'Select an age group',
      options: {'child': 'Child', 'teen': 'Teen', 'adult': 'Adult'},
    ),
    InquiryChoice(
      key: 'programme',
      label: 'Interested in',
      placeholder: 'Select a programme',
      options: {
        'camps': 'Camps',
        'training': 'Regular training',
        'unsure': 'Not sure yet',
      },
    ),
  ];
}
