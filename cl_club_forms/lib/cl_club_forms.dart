// The barrel names everything it exports, and exports only what another
// package's production code uses. A building block of a form named here
// stays in `src/`; a test that needs one imports it from there.

// Form-local models and values (pure UI, no SDK)
export 'src/models/camp_schedule_data.dart' show CampScheduleData;
export 'src/models/event_staff_member.dart' show EventStaffMember;
export 'src/models/event_timetable_value.dart' show EventTimetableValue;
export 'src/models/form_translated_text.dart' show FormTranslatedText;
export 'src/models/one_off_schedule_data.dart' show OneOffScheduleData;
export 'src/models/one_off_schedule_value.dart' show OneOffScheduleValue;
export 'src/models/programme_schedule_adjust_value.dart'
    show ProgrammeScheduleAdjustValue;
export 'src/models/programme_schedule_data.dart' show ProgrammeScheduleData;
export 'src/models/session_input.dart' show SessionInput;
export 'src/models/timetable_schedule_option.dart' show TimetableScheduleOption;
// Account forms (pure UI, no SDK / no Riverpod)
export 'src/widgets/account/change_password_form.dart'
    show ChangePasswordForm, ChangePasswordFormState;
export 'src/widgets/account/change_password_form_fields.dart'
    show ChangePasswordFormFields;
export 'src/widgets/account/forgot_password_form.dart'
    show ForgotPasswordForm, ForgotPasswordFormState;
export 'src/widgets/account/forgot_password_form_fields.dart'
    show ForgotPasswordFormFields;
export 'src/widgets/account/login_form.dart' show LoginForm, LoginFormState;
export 'src/widgets/account/login_form_fields.dart' show LoginFormFields;
// Age band of the eligibility editors (pure UI, no SDK / no Riverpod): its
// values and the read view.
export 'src/widgets/age_eligibility/age_eligibility_form_values.dart'
    show AgeEligibilityFormValues;
export 'src/widgets/age_eligibility/age_eligibility_summary.dart'
    show AgeEligibilitySummary;
export 'src/widgets/age_eligibility/age_eligibility_text.dart'
    show AgeEligibilityText;
export 'src/widgets/age_eligibility/form_age.dart' show FormAge;
// Club identity section forms (pure UI, no SDK / no Riverpod): the club's
// details, its contact block and its address, translatable fields as
// FormTranslatedText; and the one-field form that adds a language to
// translate them into.
export 'src/widgets/club_identity_form/club_address_form.dart'
    show ClubAddressForm, ClubAddressFormState;
export 'src/widgets/club_identity_form/club_address_form_fields.dart'
    show ClubAddressFormFields;
export 'src/widgets/club_identity_form/club_contact_form.dart'
    show ClubContactForm, ClubContactFormState;
export 'src/widgets/club_identity_form/club_contact_form_fields.dart'
    show ClubContactFormFields;
export 'src/widgets/club_identity_form/club_details_form.dart'
    show ClubDetailsForm, ClubDetailsFormState;
export 'src/widgets/club_identity_form/club_details_form_fields.dart'
    show ClubDetailsFormFields;
export 'src/widgets/club_identity_form/club_language_form.dart'
    show ClubLanguageForm, ClubLanguageFormState;
export 'src/widgets/club_identity_form/club_language_form_fields.dart'
    show ClubLanguageFormFields;
export 'src/widgets/credit/credit_extend_form.dart'
    show CreditExtendForm, CreditExtendFormState;
export 'src/widgets/credit/credit_form_fields.dart' show CreditFormFields;
export 'src/widgets/credit/credit_grant_form.dart'
    show CreditGrantForm, CreditGrantFormState;
export 'src/widgets/credit/credit_programme_option.dart'
    show CreditProgrammeOption;
export 'src/widgets/credit/credit_reverse_form.dart'
    show CreditReverseForm, CreditReverseFormState;
export 'src/widgets/credit/credit_transfer_form.dart'
    show CreditTransferForm, CreditTransferFormState;
// Calling an event off: a reason and, for a camp, the session to cancel
// from (pure UI, no SDK / no Riverpod).
export 'src/widgets/event_cancellation/event_cancellation_form.dart'
    show EventCancellationForm, EventCancellationFormState;
export 'src/widgets/event_cancellation/event_cancellation_form_fields.dart'
    show EventCancellationFormFields;
export 'src/widgets/event_cancellation/event_cancellation_session.dart'
    show EventCancellationSession;
// Event create form (pure UI, no SDK / no Riverpod). Form-local types; the
// host adapter maps to the SDK create call at the boundary.
export 'src/widgets/event_create/event_create_form.dart'
    show EventCreateForm, EventCreateFormState;
export 'src/widgets/event_create/event_create_form_fields.dart'
    show
        EventCreateFormFields,
        EventFormType,
        EventFormTypeLabel,
        EventFormVisibility,
        EventVenueOption;
// Event section forms (pure UI, no SDK / no Riverpod). The shared
// string-list field cluster is intentionally not exported — only the
// assembled forms are public.
export 'src/widgets/event_form/event_eligibility_form.dart'
    show EventEligibilityForm, EventEligibilityFormState;
export 'src/widgets/event_form/event_form_fields.dart'
    show EventFormFields, EventGender;
export 'src/widgets/event_form/event_form_validators.dart'
    show EventFormValidators;
export 'src/widgets/event_form/event_staff_form.dart'
    show EventStaffForm, EventStaffFormState;
// Event schedule forms (pure UI, no SDK / no Riverpod). Form-local typed
// values; the host translates to/from SDK types at the boundary.
export 'src/widgets/event_schedule/camp_schedule_form.dart'
    show CampScheduleForm, CampScheduleFormState;
export 'src/widgets/event_schedule/camp_schedule_form_fields.dart'
    show CampScheduleFormFields;
export 'src/widgets/event_schedule/event_timetable_form.dart'
    show EventTimetableForm, EventTimetableFormState;
export 'src/widgets/event_schedule/event_timetable_form_fields.dart'
    show EventTimetableFormFields;
export 'src/widgets/event_schedule/event_timetable_form_validators.dart'
    show EventTimetableFormValidators;
export 'src/widgets/event_schedule/one_off_schedule_form.dart'
    show OneOffScheduleForm, OneOffScheduleFormState;
export 'src/widgets/event_schedule/one_off_schedule_form_fields.dart'
    show OneOffScheduleFormFields;
export 'src/widgets/event_schedule/one_off_schedule_form_validators.dart'
    show OneOffScheduleFormValidators;
export 'src/widgets/event_schedule/programme_end_date_form.dart'
    show ProgrammeEndDateForm, ProgrammeEndDateFormState;
export 'src/widgets/event_schedule/programme_end_date_form_fields.dart'
    show ProgrammeEndDateFormFields;
export 'src/widgets/event_schedule/programme_schedule_adjust_form.dart'
    show ProgrammeScheduleAdjustForm, ProgrammeScheduleAdjustFormState;
export 'src/widgets/event_schedule/programme_schedule_adjust_form_fields.dart'
    show ProgrammeScheduleAdjustFormFields;
// A two-column layout that stacks on narrow surfaces
export 'src/widgets/event_schedule/two_column_grid.dart' show TwoColumnGrid;
// Group forms (pure UI, no SDK / no Riverpod). The shared eligibility field
// cluster is intentionally not exported — only the assembled forms are public.
export 'src/widgets/group_form/group_create_form.dart'
    show GroupCreateForm, GroupCreateFormState;
export 'src/widgets/group_form/group_eligibility_form.dart'
    show GroupEligibilityForm, GroupEligibilityFormState;
export 'src/widgets/group_form/group_form_fields.dart'
    show GroupFormFields, GroupGender, GroupMode;
export 'src/widgets/group_form/group_form_validators.dart'
    show GroupFormValidators;
// The privacy consent a member gives with their identity documents
export 'src/widgets/identity_documents/identity_documents_consent_form.dart'
    show IdentityDocumentsConsentForm, IdentityDocumentsConsentFormState;
// The public inquiry form: contact, or an expression of interest (pure UI,
// no SDK / no Riverpod). Its wording arrives from the host.
export 'src/widgets/inquiry/inquiry_choice.dart' show InquiryChoice;
export 'src/widgets/inquiry/inquiry_form.dart'
    show InquiryForm, InquiryFormState;
export 'src/widgets/inquiry/inquiry_form_copy.dart' show InquiryFormCopy;
export 'src/widgets/inquiry/inquiry_form_fields.dart' show InquiryFormFields;
// Location section editor: an address and a map link
export 'src/widgets/location_edit/location_edit_form.dart'
    show LocationEditForm, LocationEditFormState;
export 'src/widgets/location_edit/location_edit_form_fields.dart'
    show LocationEditFormFields;
// Occurrence reschedule form (pure UI, no SDK / no Riverpod). Reuses the
// one-off schedule field + a venue select; the host adapter diffs against the
// occurrence and sends only changed fields.
export 'src/widgets/occurrence_reschedule/occurrence_reschedule_form.dart'
    show OccurrenceRescheduleForm, OccurrenceRescheduleFormState;
export 'src/widgets/occurrence_reschedule/occurrence_reschedule_form_fields.dart'
    show OccurrenceRescheduleFormFields;
// The single-text form behind every rename dialog
export 'src/widgets/rename/rename_form.dart' show RenameForm, RenameFormState;
export 'src/widgets/rename/rename_form_fields.dart' show RenameFormFields;
// Signup form (pure UI, no SDK / no Riverpod)
export 'src/widgets/signup/signup_form.dart' show SignupForm, SignupFormState;
export 'src/widgets/signup/signup_gender.dart' show SignupGender;
export 'src/widgets/signup/username_availability_field.dart'
    show UsernameAvailabilityField;
// User form + section editors (pure UI, no SDK / no Riverpod)
export 'src/widgets/user_form/form_address.dart' show FormAddress;
export 'src/widgets/user_form/user_address_form.dart'
    show UserAddressForm, UserAddressFormState;
export 'src/widgets/user_form/user_contact_form.dart'
    show UserContactForm, UserContactFormState;
export 'src/widgets/user_form/user_form.dart' show UserForm, UserFormState;
export 'src/widgets/user_form/user_form_assembly.dart' show UserFormAssembly;
export 'src/widgets/user_form/user_form_fields.dart' show UserFormFields;
export 'src/widgets/user_form/user_personal_details_form.dart'
    show UserPersonalDetailsForm, UserPersonalDetailsFormState;
// Venue create form (pure UI, no SDK / no Riverpod)
export 'src/widgets/venue_form/venue_create_form.dart'
    show VenueCreateForm, VenueCreateFormState;
export 'src/widgets/venue_form/venue_form_fields.dart' show VenueFormFields;
export 'src/widgets/venue_form/venue_form_validators.dart'
    show VenueFormValidators;
