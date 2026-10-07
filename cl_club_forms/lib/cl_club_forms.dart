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
// Age band of the eligibility editors (pure UI, no SDK / no Riverpod): its
// values and the read view.
export 'src/widgets/age_eligibility/age_eligibility_form_values.dart'
    show AgeEligibilityFormValues;
export 'src/widgets/age_eligibility/age_eligibility_summary.dart'
    show AgeEligibilitySummary;
export 'src/widgets/age_eligibility/age_eligibility_text.dart'
    show AgeEligibilityText;
export 'src/widgets/age_eligibility/form_age.dart' show FormAge;
export 'src/widgets/change_password_form.dart' show ChangePasswordForm;
// Club identity form (pure UI, no SDK / no Riverpod): the club's name,
// inquiry email and public contact block, translatable fields as
// FormTranslatedText.
export 'src/widgets/club_identity_form/club_identity_form.dart'
    show ClubIdentityForm, ClubIdentityFormState;
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
export 'src/widgets/event_form/organizer_coaches_editor.dart'
    show OrganizerCoachesEditor, OrganizerCoachesEditorState;
// Event schedule forms (pure UI, no SDK / no Riverpod). Form-local typed
// values; the host translates to/from SDK types at the boundary.
export 'src/widgets/event_schedule/camp_schedule_form.dart'
    show CampScheduleForm, CampScheduleFormState;
export 'src/widgets/event_schedule/event_timetable_form.dart'
    show EventTimetableForm, EventTimetableFormState;
export 'src/widgets/event_schedule/event_timetable_form_validators.dart'
    show EventTimetableFormValidators;
export 'src/widgets/event_schedule/one_off_schedule_form.dart'
    show OneOffScheduleForm, OneOffScheduleFormState;
export 'src/widgets/event_schedule/one_off_schedule_form_validators.dart'
    show OneOffScheduleFormValidators;
export 'src/widgets/event_schedule/programme_end_date_form.dart'
    show ProgrammeEndDateForm, ProgrammeEndDateFormState;
export 'src/widgets/event_schedule/programme_schedule_adjust_form.dart'
    show ProgrammeScheduleAdjustForm, ProgrammeScheduleAdjustFormState;
// A two-column layout that stacks on narrow surfaces
export 'src/widgets/event_schedule/two_column_grid.dart' show TwoColumnGrid;
export 'src/widgets/forgot_password_form.dart' show ForgotPasswordForm;
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
export 'src/widgets/location_edit_form.dart'
    show LocationEditForm, LocationEditFormState, LocationEditResult;
export 'src/widgets/login_form.dart' show LoginForm;
// Occurrence reschedule form (pure UI, no SDK / no Riverpod). Reuses the
// one-off schedule field + a venue select; the host adapter diffs against the
// occurrence and sends only changed fields.
export 'src/widgets/occurrence_reschedule/occurrence_reschedule_form.dart'
    show OccurrenceRescheduleForm, OccurrenceRescheduleFormState;
export 'src/widgets/occurrence_reschedule/occurrence_reschedule_form_fields.dart'
    show OccurrenceRescheduleFormFields;
export 'src/widgets/rename_form.dart' show RenameForm, RenameFormState;
// Signup form (pure UI, no SDK / no Riverpod)
export 'src/widgets/signup/signup_form.dart'
    show SignupForm, SignupGender, SignupSubmitResult;
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
export 'src/widgets/user_form/user_personal_details_form.dart'
    show UserPersonalDetailsForm, UserPersonalDetailsFormState;
// Venue create form (pure UI, no SDK / no Riverpod)
export 'src/widgets/venue_form/venue_create_form.dart'
    show VenueCreateForm, VenueCreateFormState;
export 'src/widgets/venue_form/venue_form_validators.dart'
    show VenueFormValidators;
