// The barrel names everything it exports, and exports only what another
// package's production code uses. A building block of a widget named here
// stays in `src/`; a test that needs one imports it from there.

// Responsive layout breakpoints
export 'src/constants/breakpoints.dart' show isMobileWidth;
// Evaluations (pure UI, no SDK / no Riverpod, #173): form-local types, the
// answer input, the item editor, the layout editor, the template create
// form, the fill body and the read-only body. The host adapts SDK models.
export 'src/constants/evaluation_spacing.dart' show EvaluationSpacing;
// Extensions
export 'src/extensions/string_extensions.dart' show StringExtensions;
export 'src/models/evaluation_answer_value.dart' show EvaluationAnswerValue;
export 'src/models/evaluation_choice.dart' show EvaluationChoice;
export 'src/models/evaluation_item_kind.dart' show EvaluationItemKind;
export 'src/models/evaluation_item_value.dart' show EvaluationItemValue;
export 'src/models/evaluation_layout_entry.dart' show EvaluationLayoutEntry;
export 'src/models/evaluation_outline_edit.dart' show EvaluationOutlineEdit;
export 'src/models/evaluation_rating_scale.dart' show EvaluationRatingScale;
export 'src/models/evaluation_rating_style.dart' show EvaluationRatingStyle;
export 'src/models/evaluation_start_options.dart'
    show EvaluationStartChoice, EvaluationStartMember;
export 'src/models/evaluation_template_create_value.dart'
    show EvaluationTemplateCreateValue;
// Theme
export 'src/theme/custom_colors.dart'
    show FilmRollColorsExtension, darkCustomColors, lightCustomColors;
export 'src/theme/semantic_colors.dart' show SemanticColors;
export 'src/theme/text_theme_extensions.dart' show ClubTextTheme;
// Reaching a person (pure UI, no SDK / no Riverpod, #32): the launcher
// (`launchContactUrl`), and a phone number or an email address with its
// actions (`PhoneContact`, `EmailContact`).
export 'src/utils/launch_contact_url.dart' show launchContactUrl;
// Opening media outside the app
export 'src/utils/open_pdf_download.dart' show openPdfDownload;
export 'src/utils/phone_number.dart' show PhoneNumber;
export 'src/widgets/action_button.dart' show ActionButton;
export 'src/widgets/action_icon.dart' show ActionIcon;
export 'src/widgets/admin_user_review/admin_user_review_form.dart'
    show AdminUserReviewForm;
export 'src/widgets/admin_user_review/admin_user_review_form_data.dart'
    show AdminUserReviewFormData;
export 'src/widgets/age_eligibility/no_longer_eligible_label.dart'
    show NoLongerEligibleLabel;
export 'src/widgets/avatar_circle_variant.dart' show AvatarCircleVariant;
export 'src/widgets/bordered_menu_list.dart' show BorderedMenuItem;
// Broadcast compose box (pure UI, no SDK / no Riverpod). Shared by the
// all-users broadcast panel and the per-group message section.
export 'src/widgets/broadcast_composer.dart'
    show BroadcastComposeResult, BroadcastComposer;
export 'src/widgets/cards/action_group.dart' show ActionGroup;
// Cards (umbrella #189)
export 'src/widgets/cards/action_item.dart' show ActionItem;
export 'src/widgets/cards/entity_card.dart' show EntityCard;
export 'src/widgets/cards/entity_image.dart' show EntityImage;
export 'src/widgets/confirm_dialog.dart' show ConfirmDialog;
export 'src/widgets/contact/email_contact.dart' show EmailContact;
export 'src/widgets/contact/phone_contact.dart' show PhoneContact;
// Content page hero
export 'src/widgets/content_page_hero_section.dart' show ContentPageHeroSection;
export 'src/widgets/credentialed_network_image.dart'
    show CredentialedNetworkImage;
export 'src/widgets/credit/credit_count_chip.dart' show CreditCountChip;
export 'src/widgets/date_day_label.dart' show DateDayLabel;
export 'src/widgets/detail_row.dart' show DetailRow;
export 'src/widgets/error_view.dart' show ErrorTone, ErrorView;
export 'src/widgets/evaluation/fill/evaluation_fill_body.dart'
    show EvaluationFillBody, EvaluationFillBodyState;
export 'src/widgets/evaluation/fill/evaluation_fill_fields.dart'
    show EvaluationFillFields;
export 'src/widgets/evaluation/inputs/evaluation_answer_input.dart'
    show EvaluationAnswerInput;
export 'src/widgets/evaluation/item_form/evaluation_item_form.dart'
    show EvaluationItemForm, EvaluationItemFormState;
export 'src/widgets/evaluation/item_form/evaluation_item_form_values.dart'
    show EvaluationItemFormValues;
export 'src/widgets/evaluation/layout/evaluation_layout_editor.dart'
    show EvaluationLayoutEditor;
export 'src/widgets/evaluation/read/evaluation_read_body.dart'
    show EvaluationReadBody;
export 'src/widgets/evaluation/start/evaluation_period_form.dart'
    show EvaluationPeriodForm, EvaluationPeriodFormState;
export 'src/widgets/evaluation/start/evaluation_start_form.dart'
    show EvaluationStartForm, EvaluationStartFormState;
export 'src/widgets/evaluation/start/evaluation_start_form_fields.dart'
    show EvaluationStartFormFields;
export 'src/widgets/evaluation/template/evaluation_template_create_form.dart'
    show EvaluationTemplateCreateForm, EvaluationTemplateCreateFormState;
export 'src/widgets/evaluation/template/evaluation_template_create_form_fields.dart'
    show EvaluationTemplateCreateFormFields;
export 'src/widgets/evaluation/template/evaluation_template_form_validators.dart'
    show EvaluationTemplateFormValidators;
// Read-only calendar of a camp's schedule
export 'src/widgets/event_schedule/camp_schedule_calendar.dart'
    show CampScheduleCalendar;
// Highlight Media
export 'src/widgets/highlight_media/highlight_media_orchestrator.dart'
    show HighlightMediaOrchestrator;
// Identity documents (pure UI, no SDK / no Riverpod): the uploader, which
// saves each file as it is added or removed.
export 'src/widgets/identity_documents/identity_docs_upload_exception.dart'
    show IdentityDocsUploadException;
export 'src/widgets/identity_documents/identity_document_slot.dart'
    show IdentityDocumentSlot;
export 'src/widgets/identity_documents/identity_documents_picker.dart'
    show IdentityDocumentsPicker, PickedImage, defaultIdentityDocumentsPicker;
export 'src/widgets/identity_documents/identity_documents_uploader.dart'
    show IdentityDocumentsUploader;
// Image upload affordance (cover image replace/remove) — shared by event,
// venue, and group connected affordances.
export 'src/widgets/image_upload/image_picker_confirm.dart'
    show ConfirmImagePicker, pickAndConfirmImage, pickImageReportingErrors;
export 'src/widgets/image_upload/image_upload_affordance.dart'
    show CircleIconButton, ImageUploadAffordance;
export 'src/widgets/loading_view.dart' show LoadingView;
export 'src/widgets/map_embed.dart' show MapEmbed;
// Markdown
export 'src/widgets/markdown/editable_markdown.dart' show EditableMarkdown;
export 'src/widgets/markdown/themed_markdown.dart' show ThemedMarkdown;
export 'src/widgets/mobile_menu_drawer.dart' show MobileMenuDrawer;
export 'src/widgets/pagination_bar.dart' show PaginationBar;
export 'src/widgets/read_only_field.dart' show ReadOnlyField;
// Section-wise editor chrome (pure UI, no SDK / no Riverpod)
export 'src/widgets/section_editor/editable_section_card.dart'
    show EditableSectionCard;
export 'src/widgets/section_editor/section_edit_button.dart'
    show SectionEditButton;
// Rubber-stamp mark, monochrome by default
export 'src/widgets/stamp_badge.dart' show StampBadge;
export 'src/widgets/status_badge.dart' show StatusBadge;
export 'src/widgets/title_row.dart' show TitleRow;
export 'src/widgets/user_selection_dialog.dart'
    show PickerUser, UserSelectionDialogContent, showUserSelectionDialog;
